"""Builds the Meridian's wardrobe: real clothes fitted over the Universal Base Characters.

Run with Blender's Python module, SciPy and scikit-image (pip install bpy scipy scikit-image into
a venv, Python 3.13):
    python tools/blender/wardrobe.py assets/people assets/people/outfits [outfit ...] [male|female]
WARDROBE_PARTS=1 keeps the suit's jacket, lapels, collar and pocket flaps and the shirt's front,
collar and cuffs as separate meshes, to look at each one.

Writes <outfit>_<body>.gltf and .bin into the output folder for each outfit and body: the base
body's own skeleton (unchanged, so the Universal Animation Libraries drive it), its head and hands
(the skin under the clothes is cut away so it can't show through), its eyes and brows, and the
clothes as separate meshes named for what they are (Suit, Skirt, Shirt, Tie, Trousers, Shoes,
Buttons, Pin, Earpiece; Dress, Shoes, Necklace), each skinned to the same bones. The game paints
each by its name (Person).

How the clothes are made: the body becomes a distance field on a grid, and a "closing" of it (the
body with every hollow narrower than the cloth's stiffness filled in) is the surface cloth lies on,
over the chest rather than into every muscle. Shells start as copies of the body's own faces, are
pushed onto that surface plus some ease, hang straight down the arms and legs, and are smoothed.
The jacket's skirt, the collars, lapels, shirt, tie, buttons and shoes are built on top: the
collars follow lines round the neck, and the shoes are the closing of the feet. On the female
body, smoothed hulls of the bust and the seat join the field first, so cloth bridges the
cleavage, the underbust and the cleft between the buttocks rather than following them. Every
point takes its skin weights from the nearest point of the body.

Outfits so far:
- halberd_suit (male and female): the dark suit, white shirt and tie Halberd Security's door
  staff wear, with an earpiece and the company pin. The women's cut is a fitted, shorter jacket
  with a higher button, a softer collar and pointed shoes.
- evening_dress (female): a long gala gown, a fitted bodice with a V at the front, a low scoop at
  the back and straps, a waistband, and a skirt that falls to the floor and flares a little more
  at the back; evening shoes and a fine chain with a drop. The skirt is a ring of rays from the
  waist down, never narrower than the ring above it, so it hangs from the hips over the legs.
"""
import bpy, bmesh, math, os, sys
import numpy as np
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
from scipy import ndimage, sparse
from scipy.interpolate import CubicSpline

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
PEOPLE, OUT = ARGS[0], ARGS[1]
WANT = set(ARGS[2:])
BODIES = {"male": "Superhero_Male_FullBody.gltf", "female": "Superhero_Female_FullBody.gltf"}
UP = np.array([0.0, 0.0, 1.0])
FWD = np.array([0.0, -1.0, 0.0])  # the bodies face -Y in Blender


# --- The body ----------------------------------------------------------------------------------

class Body:
    """The base body: skeleton, skin mesh, weights and a few measurements, in its rest space
    (Blender: Z up, facing -Y, a T-pose)."""

    def __init__(self, kind):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=os.path.join(PEOPLE, BODIES[kind]), merge_vertices=True)
        self.kind = kind
        self.arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
        meshes = [o for o in bpy.data.objects if o.type == 'MESH']
        self.obj = max(meshes, key=lambda o: len(o.data.vertices))
        self.extras = [o for o in meshes if o is not self.obj and o.parent == self.arm]
        for o in meshes:
            if o is not self.obj and o not in self.extras:
                bpy.data.objects.remove(o)
        me = self.obj.data
        self.co = np.array([v.co[:] for v in me.vertices])
        self.groups = [g.name for g in self.obj.vertex_groups]
        W = np.zeros((len(me.vertices), len(self.groups)), np.float32)
        for v in me.vertices:
            for g in v.groups:
                W[v.index, g.group] = g.weight
        self.W = W
        me.calc_loop_triangles()
        self.tris = np.array([t.vertices[:] for t in me.loop_triangles])
        self.bvh = BVHTree.FromPolygons([Vector(c) for c in self.co], self.tris.tolist())

        def total(*prefixes):
            cols = [i for i, n in enumerate(self.groups) if n.startswith(prefixes)]
            return W[:, cols].sum(1)
        self.w_head = total("Head", "neck_01")
        self.w_hand = total("hand_", "index_", "middle_", "ring_", "pinky_", "thumb_")
        self.w_foot = total("foot_", "ball_")
        self.w_leg = total("thigh_", "calf_")
        self.w_pelvis = total("pelvis")

        def bone(n):
            return np.array(self.arm.matrix_world @ self.arm.data.bones[n].head_local)
        self.bone = bone
        self.hand = bone("hand_l")
        self.shoulder = bone("upperarm_l")
        self.hip = bone("thigh_l")
        self.ankle = bone("foot_l")
        self.pelvis_z = bone("pelvis")[2]
        self.neck_z = bone("neck_01")[2]
        self.floor = self.co[:, 2].min()
        self.top = self.co[:, 2].max()

    def triangles(self, vert_mask=None):
        """The body's triangles as corner positions, optionally only those touching vert_mask."""
        t = self.tris
        if vert_mask is not None:
            t = t[vert_mask[t].any(1)]
        return self.co[t]

    def weights(self, P, top=4):
        """Skin weights for points near the body: those of the nearest point on it."""
        out = np.zeros((len(P), len(self.groups)), np.float32)
        for i, p in enumerate(P):
            loc, _n, ti, _d = self.bvh.find_nearest(Vector(p))
            a, b, c = self.co[self.tris[ti]]
            out[i] = barycentric(np.array(loc), a, b, c) @ self.W[self.tris[ti]]
        return normalize_weights(out, top)

    def group(self, name):
        return self.groups.index(name)


def barycentric(p, a, b, c):
    v0, v1, v2 = b - a, c - a, p - a
    d00, d01, d11 = v0 @ v0, v0 @ v1, v1 @ v1
    d20, d21 = v2 @ v0, v2 @ v1
    den = d00 * d11 - d01 * d01
    if abs(den) < 1e-12:
        return np.array([1.0, 0.0, 0.0])
    v = (d11 * d20 - d01 * d21) / den
    w = (d00 * d21 - d01 * d20) / den
    bc = np.clip(np.array([1.0 - v - w, v, w]), 0.0, 1.0)
    return bc / bc.sum()


def normalize_weights(W, top=4):
    W = W.copy()
    if W.shape[1] > top:
        drop = np.argsort(-W, axis=1)[:, top:]
        np.put_along_axis(W, drop, 0.0, axis=1)
    return W / np.maximum(W.sum(1, keepdims=True), 1e-6)


# --- The cloth surface -------------------------------------------------------------------------

def hull_filler(P, rounds=3):
    """Triangles of the convex hull of some points, its ridges rounded off (by smoothing, which
    sinks it a little where it was sharp). Added to a body's field, cloth lies over the hull
    instead of following the body into a hollow; inside the body it's harmless, since cloth
    only meets the outside of the field."""
    from scipy.spatial import ConvexHull
    bm = bmesh.new()
    vs = new_verts(bm, P)
    for t in ConvexHull(P).simplices:
        try:
            bm.faces.new([vs[i] for i in t])
        except ValueError:
            pass
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    for _ in range(rounds):
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=1, use_grid_fill=True)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        smooth(bm, 6, lam=0.6, mu=-0.6)
    bm.verts.ensure_lookup_table()
    P = coords(bm)
    return P[np.array([[v.index for v in f.verts] for f in bm.faces])]


def bust_filler(body, z0=1.17, z1=1.43, x1=0.15):
    """The front of the female body's chest filled over the cleavage and under the bust: cloth
    falls from the bust rather than into them."""
    c = body.co
    arm = sum(body.W[:, body.group(n)] for n in ("upperarm_l", "upperarm_r", "clavicle_l", "clavicle_r"))
    m = (c[:, 2] > z0) & (c[:, 2] < z1) & (c[:, 1] < 0.0) & (np.abs(c[:, 0]) < x1) & (arm < 0.3)
    return hull_filler(c[m])


def seat_filler(body, z0=0.74, z1=1.02, x1=0.2):
    """The back of the female body's hips filled over the cleft of the seat: a jacket hangs
    straight across it."""
    c = body.co
    near = (np.abs(c[:, 2] - body.pelvis_z) < 0.02) & (np.abs(c[:, 0]) < 0.05)
    cy = 0.5 * (c[near][:, 1].min() + c[near][:, 1].max())
    m = (c[:, 2] > z0) & (c[:, 2] < z1) & (c[:, 1] > cy) & (np.abs(c[:, 0]) < x1)
    return hull_filler(c[m])


def surface_points(tris, step, seed=7):
    """Points over triangles, about one per step squared, plus the corners."""
    rng = np.random.default_rng(seed)
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    area = 0.5 * np.linalg.norm(np.cross(b - a, c - a), axis=1)
    n = np.ceil(area / (step * step) * 2.0).astype(int) + 2
    rep = np.repeat(np.arange(len(tris)), n)
    r1 = np.sqrt(rng.random(len(rep)))
    r2 = rng.random(len(rep))
    P = (1 - r1)[:, None] * a[rep] + (r1 * (1 - r2))[:, None] * b[rep] + (r1 * r2)[:, None] * c[rep]
    return np.concatenate([P, tris.reshape(-1, 3)])


class Field:
    """Distances round some of the body on a grid. D is the distance to its surface; for a cloth
    stiffness R, E is the distance to everywhere a ball of radius R can reach from outside, so
    E = R - ease is cloth lying over the body with that ease, bridging hollows narrower than R."""

    def __init__(self, tris, h=0.006, pad=0.12, box=None):
        """box (lo, hi) limits the grid to part of the triangles: cut through a closed body, its
        inside stays apart from the outside."""
        pts = tris.reshape(-1, 3)
        lo, hi = pts.min(0) - pad, pts.max(0) + pad
        if box is not None:
            lo, hi = np.maximum(lo, box[0]), np.minimum(hi, box[1])
        self.lo = lo
        self.h = h
        shape = tuple(np.ceil((hi - self.lo) / h).astype(int) + 1)
        idx = np.round((surface_points(tris, h * 0.45) - self.lo) / h).astype(int)
        if box is not None:
            idx = idx[np.all((idx >= 0) & (idx < np.array(shape)), axis=1)]
        surf = np.zeros(shape, bool)
        surf[tuple(idx.T)] = True
        self.D = (ndimage.distance_transform_edt(~surf) * h).astype(np.float32)
        self.closings = {}

    def closing(self, R):
        if R not in self.closings:
            lab, _ = ndimage.label(self.D > R)
            outside = lab == lab[0, 0, 0]
            E = (ndimage.distance_transform_edt(~outside) * self.h).astype(np.float32)
            self.closings[R] = (E, np.gradient(E, self.h))
        return self.closings[R]

    def at(self, A, P):
        return ndimage.map_coordinates(A, ((np.asarray(P, float) - self.lo) / self.h).T, order=1, mode='nearest')

    def onto(self, P, R, ease, iters=12, outward_only=False):
        """Moves points onto the cloth surface (or only out to it)."""
        E, G = self.closing(R)
        P = np.array(P, float)
        for _ in range(iters):
            e = self.at(E, P) - (R - ease)
            if outward_only:
                e = np.maximum(e, 0.0)
            g = np.stack([self.at(Gi, P) for Gi in G], 1)
            g /= np.maximum(np.linalg.norm(g, axis=1, keepdims=True), 1e-6)
            P -= np.clip(e, -0.02, 0.02)[:, None] * g
        return P

    def reach(self, centers, dirs, R, ease, far=0.5, step=0.0015, miss=None):
        """How far out from each center, along its direction, the cloth surface is: walks in from far.
        A ray that never meets it (from a gap between the legs) gives miss, when one is given."""
        centers = np.asarray(centers, float)
        dirs = np.asarray(dirs, float)
        E, _ = self.closing(R)
        s = np.arange(far, 0.0, -step)
        P = centers[:, None, :] + dirs[:, None, :] * s[None, :, None]
        e = self.at(E, P.reshape(-1, 3)).reshape(len(centers), len(s)) - (R - ease)
        inside = e >= 0.0
        first = np.where(inside.any(1), inside.argmax(1), len(s) - 1)
        r = s[first]
        prev = np.clip(first - 1, 0, None)
        rows = np.arange(len(centers))
        e0, e1 = e[rows, prev], e[rows, first]
        t = np.where(first > 0, -e0 / np.where(np.abs(e1 - e0) > 1e-9, e1 - e0, 1.0), 0.0)
        if miss is not None:
            return np.where(inside.any(1), s[prev] - np.clip(t, 0.0, 1.0) * step, miss)
        return s[prev] - t * step

    def push_out(self, P, gap):
        """Moves points out until they're at least gap from the body's surface."""
        g = np.gradient(self.D, self.h) if not hasattr(self, "_gD") else self._gD
        self._gD = g
        P = np.array(P, float)
        for _ in range(10):
            d = self.at(self.D, P)
            need = np.maximum(gap - d, 0.0)
            if need.max() < 1e-4:
                break
            n = np.stack([self.at(gi, P) for gi in g], 1)
            n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-6)
            P += need[:, None] * n
        return P


# --- Mesh helpers ------------------------------------------------------------------------------

def coords(bm):
    bm.verts.ensure_lookup_table()
    return np.array([v.co[:] for v in bm.verts])


def set_coords(bm, P):
    bm.verts.ensure_lookup_table()
    for v, p in zip(bm.verts, P):
        v.co = Vector(p)


def body_piece(body, keep):
    """A bmesh of the body faces whose corners are all in keep."""
    bm = bmesh.new()
    bm.from_mesh(body.obj.data)
    bm.verts.ensure_lookup_table()
    kill = [f for f in bm.faces if not all(keep[v.index] for v in f.verts)]
    bmesh.ops.delete(bm, geom=kill, context='FACES')
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context='VERTS')
    return bm


def cut(bm, co, no, faces=None):
    """Cuts away everything on the side of the plane its normal points to."""
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-6, plane_co=Vector(co), plane_no=Vector(no), clear_outer=True)
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context='VERTS')


def cut_level(bm, g):
    """Cuts away everything where g(point) > 0, along the curve where it crosses 0 (a plane cut,
    bent). Returns the new edge's points near which g was 0."""
    val = {v: g(np.array(v.co[:])) for v in bm.verts}
    new = set()
    for e in [e for e in bm.edges if (val[e.verts[0]] > 0) != (val[e.verts[1]] > 0)]:
        a, b = e.verts
        t = val[a] / (val[a] - val[b])
        pa, pb = a.co.copy(), b.co.copy()
        _e, nv = bmesh.utils.edge_split(e, a, t)
        nv.co = pa.lerp(pb, t)
        val[nv] = 0.0
        new.add(nv)
    for f in list(bm.faces):
        vs = [v for v in f.verts if v in new]
        if len(vs) == 2:
            bmesh.ops.connect_verts(bm, verts=vs)
    kill = [f for f in bm.faces if max(val[v] for v in f.verts) > 0]
    bmesh.ops.delete(bm, geom=kill, context='FACES')
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    return [v for v in new if v.is_valid]


def subdivide(bm, times=1):
    for _ in range(times):
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=1, use_grid_fill=True)


def smooth(bm, iters=6, lam=0.5, mu=-0.53, pin=None):
    """Taubin smoothing: rounds off lumps without shrinking. Boundary points slide along the boundary."""
    bm.verts.ensure_lookup_table()
    n = len(bm.verts)
    rows, cols = [], []
    for v in bm.verts:
        edges = [e for e in v.link_edges if e.is_boundary] if v.is_boundary else v.link_edges
        for e in edges:
            rows.append(v.index)
            cols.append(e.other_vert(v).index)
    A = sparse.csr_matrix((np.ones(len(rows)), (rows, cols)), shape=(n, n))
    deg = np.asarray(A.sum(1)).ravel()
    L = sparse.diags(1.0 / np.maximum(deg, 1)) @ A
    P = coords(bm)
    move = np.ones(n) if pin is None else (~pin).astype(float)
    move[deg == 0] = 0.0
    for _ in range(iters):
        for k in (lam, mu):
            P = P + k * (L @ P - P) * move[:, None]
    set_coords(bm, P)


def settle(bm, F, R, ease, rounds=4, iters=4, fixed=None):
    """Smooths and puts back on the cloth surface a few times, so points spread evenly over it
    instead of bunching (and folding) where the cloth bridges a hollow."""
    for _ in range(rounds):
        smooth(bm, iters, pin=fixed)
        P = coords(bm)
        Q = F.onto(P, R, ease, iters=6)
        if fixed is not None:
            Q[fixed] = P[fixed]
        set_coords(bm, Q)


def drape(P, sel, a, b, taper, t0=0.0, bins=32, dt=0.015):
    """Lets cloth hang straight along a limb from a to b: going down the limb, the cloth's radius at
    each angle shrinks by at most taper per meter, so it falls past the calf or forearm rather than
    following it in."""
    a = np.asarray(a, float)
    d = np.asarray(b, float) - a
    d /= np.linalg.norm(d)
    u = np.cross(d, [0.0, 1.0, 0.0])
    if np.linalg.norm(u) < 0.1:
        u = np.cross(d, [1.0, 0.0, 0.0])
    u /= np.linalg.norm(u)
    v = np.cross(d, u)
    Q = P[sel] - a
    t = Q @ d
    Rv = Q - t[:, None] * d
    r = np.linalg.norm(Rv, axis=1)
    th = np.arctan2(Rv @ v, Rv @ u)
    ib = np.floor((th + np.pi) / (2 * np.pi) * bins).astype(int) % bins
    it = np.clip(np.floor(t / dt).astype(int), 0, None)
    nt = it.max() + 1
    rmax = np.full((bins, nt), -1.0)
    np.maximum.at(rmax, (ib, it), r)
    rmax = np.maximum(rmax, np.maximum(np.roll(rmax, 1, 0), np.roll(rmax, -1, 0)) - 0.004)
    prof = rmax.copy()
    for j in range(max(int(t0 / dt), 0) + 1, nt):
        prof[:, j] = np.maximum(prof[:, j], prof[:, j - 1] - taper * dt)
    target = prof[ib, it]
    ramp = np.clip((t - t0) / 0.05, 0.0, 1.0)
    r_new = r + np.maximum(target - r, 0.0) * ramp
    P = P.copy()
    P[sel] = a + t[:, None] * d + Rv / np.maximum(r, 1e-6)[:, None] * r_new[:, None]
    return P


def grid_faces(bm, rows, closed=False, flip=False):
    """Faces between rows of vertices (lists of equal length)."""
    out = []
    for i in range(len(rows) - 1):
        a, b = rows[i], rows[i + 1]
        n = len(a)
        for j in range(n if closed else n - 1):
            k = (j + 1) % n
            q = [a[j], a[k], b[k], b[j]]
            if flip:
                q.reverse()
            if len({id(x) for x in q}) == 4:
                out.append(bm.faces.new(q))
    return out


def new_verts(bm, P):
    return [bm.verts.new(Vector(p)) for p in P]


def solidify(bm, thickness, flip=False, even=True):
    """Gives an open sheet some thickness, inwards, with closed edges. Even thickness blows up
    at a sharp fold, so folded sheets turn it off."""
    me = bpy.data.meshes.new("tmp")
    bm.to_mesh(me)
    ob = bpy.data.objects.new("tmp", me)
    bpy.context.scene.collection.objects.link(ob)
    m = ob.modifiers.new("solid", 'SOLIDIFY')
    m.thickness = thickness
    m.offset = -1.0 if not flip else 1.0
    m.use_even_offset = even
    m.use_rim = True
    dg = bpy.context.evaluated_depsgraph_get()
    me2 = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    out = bmesh.new()
    out.from_mesh(me2)
    bpy.data.objects.remove(ob)
    bpy.data.meshes.remove(me)
    bpy.data.meshes.remove(me2)
    return out


def recalc(bm):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])


def bvh_of(bm):
    bm.verts.ensure_lookup_table()
    return BVHTree.FromBMesh(bm)


def hit(bvh, origin, direction):
    loc, nrm, _i, _d = bvh.ray_cast(Vector(origin), Vector(direction))
    if loc is None:
        return None, None
    return np.array(loc), np.array(nrm)


def disc(bm, center, normal, radius, depth, segments=12, spin=0.0):
    """A little flat cylinder standing on a surface (buttons, the pin)."""
    n = Vector(normal).normalized()
    rot = n.to_track_quat('Z', 'Y').to_matrix().to_4x4()
    m = Matrix.Translation(Vector(center) + n * depth * 0.5) @ rot @ Matrix.Rotation(spin, 4, 'Z')
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments, radius1=radius,
                          radius2=radius * 0.92, depth=depth, matrix=m)


def tube(bm, points, radius, segments=8):
    """A tube along a polyline (the earpiece's cable)."""
    pts = [np.asarray(p, float) for p in points]
    rings = []
    prev_u = None
    for i, p in enumerate(pts):
        t = pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]
        t /= np.linalg.norm(t)
        u = np.cross(t, [0.0, 0.0, 1.0]) if prev_u is None else prev_u - (prev_u @ t) * t
        if np.linalg.norm(u) < 1e-3:
            u = np.cross(t, [1.0, 0.0, 0.0])
        u /= np.linalg.norm(u)
        prev_u = u
        v = np.cross(t, u)
        ring = [p + radius * (math.cos(a) * u + math.sin(a) * v) for a in np.linspace(0, 2 * np.pi, segments, endpoint=False)]
        rings.append(new_verts(bm, ring))
    grid_faces(bm, rings, closed=True)
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])


def neck_ring(body, phis, zs, out):
    """Points round the neck: from the neck's middle, out through the skin at each angle and height
    (the neck itself higher up, the top of the chest, back and shoulders lower down), then out more."""
    c = body.co
    near = (np.abs(c[:, 2] - body.neck_z) < 0.02) & (np.abs(c[:, 0]) < 0.09)
    cy = 0.5 * (c[near][:, 1].min() + c[near][:, 1].max())
    pts = []
    for phi, z in zip(phis, zs):
        d = np.array([math.sin(phi), -math.cos(phi), 0.0])
        o = np.array([0.0, cy, z])
        p, _n = hit(body.bvh, o, d)
        if p is None or np.linalg.norm(p - o) > 0.2:
            p = o + d * 0.08
        pts.append(p + d * out)
    return np.array(pts)


def neck_round(body, cy, z, phis, out, rmax=0.125, bins=36):
    """Points round the neck at a height: at each angle, the outermost skin within rmax of the
    neck's middle (the neck, or the top of the chest and back where it meets them), then out more."""
    c = body.co
    dx, dy = c[:, 0], c[:, 1] - cy
    r = np.hypot(dx, dy)
    m = (np.abs(c[:, 2] - z) < 0.009) & (r < rmax)
    th = np.arctan2(dx[m], -dy[m]) % (2 * np.pi)
    ib = (th / (2 * np.pi) * bins).astype(int) % bins
    prof = np.full(bins, np.nan)
    for i in range(bins):
        if (ib == i).any():
            prof[i] = r[m][ib == i].max()
    good = ~np.isnan(prof)
    idx = np.arange(bins)
    prof = np.interp(idx, idx[good], prof[good], period=bins)
    prof = (np.roll(prof, 1) + 2 * prof + np.roll(prof, -1)) / 4
    centers = (idx + 0.5) / bins * 2 * np.pi
    rr = np.interp(np.asarray(phis) % (2 * np.pi), centers, prof, period=2 * np.pi) + out
    return np.stack([np.sin(phis) * rr, cy - np.cos(phis) * rr, np.full(len(phis), z)], 1)


def neck_ring_at(body, s, phis, dz, out, line=None):
    """neck_round along the neckline (or another line round the neck), raised by dz."""
    zs = (line or s.neckline)(np.asarray(phis)) + dz
    return np.array([neck_round(body, s.neck_y, z, [phi], out)[0] for phi, z in zip(phis, zs)])


# --- Pieces of the Halberd suit ----------------------------------------------------------------

class Suit:
    """The Halberd suit's measurements, from the body's bones."""

    def __init__(self, body):
        b = body
        self.female = b.kind == "female"
        self.sleeve = b.hand[0] - 0.05            # where the jacket's sleeves end
        self.cuff = b.hand[0] - 0.037             # and the shirt's cuffs
        self.skin_hand = b.hand[0] - 0.08         # the body's skin is kept beyond this
        self.z_cut = b.pelvis_z + 0.05            # the jacket's shell ends here, its skirt hangs below
        self.z_skirt = self.z_cut + 0.035         # the skirt starts here, tucked inside the shell
        self.z_hem = b.pelvis_z - (0.11 if self.female else 0.17)
        self.z_button = b.pelvis_z + (0.18 if self.female else 0.15)   # the top button: the bottom of the V
        self.z_split = b.pelvis_z + 0.04          # the fronts part below here
        self.z_gorge = b.neck_z - (0.09 if self.female else 0.052)     # the top of the lapels
        self.x_gorge = 0.07 if self.female else 0.075
        self.z_trousers = b.pelvis_z + 0.09
        self.z_ankle = b.ankle[2] + 0.014         # trousers are cut here and hemmed below
        self.R_jacket, self.ease_jacket = 0.05, 0.017
        self.R_skirt, self.ease_skirt = (0.1, 0.028) if self.female else (0.06, 0.03)
        self.skirt_blend = 0.1 if self.female else 0.04   # how far below the waist the skirt eases out
        self.flap_x = (0.065, 0.17) if self.female else (0.075, 0.215)   # the pocket flaps' ends
        self.R_shirt, self.ease_shirt = 0.03, 0.006
        self.R_trousers, self.ease_trousers = 0.03, 0.01
        self.trouser_taper = 0.09 if self.female else 0.06
        self.collar_h = 0.034 if self.female else 0.045     # the shirt collar's height
        self.collar_dip = 0.026 if self.female else 0.032   # and how far its points dip
        self.pin_t = 0.97 if self.female else 0.72           # how far up the lapel the pin is
        self.shirt_x = 0.14 if self.female else 0.11        # the shirt's front reaches this far out
        c = b.co
        near = (np.abs(c[:, 2] - b.neck_z) < 0.02) & (np.abs(c[:, 0]) < 0.09)
        self.neck_y = 0.5 * (c[near][:, 1].min() + c[near][:, 1].max())
        # The neckline's height round the neck, from the front (0) to the back (180), over the
        # neck's bone: down at the gorge, up the sides of the neck over the shoulders' slope, and
        # a little lower again at the back.
        # The female neck is longer and slimmer, and meets the shoulders below its bone.
        at = np.radians([0, 28, 60, 90, 120, 150, 180])
        if self.female:
            dz = np.array([-0.08, -0.074, -0.012, 0.018, 0.018, 0.006, -0.002])
        else:
            dz = np.array([-0.052, -0.046, 0.02, 0.05, 0.05, 0.035, 0.028])
        self._neckline = CubicSpline(at, b.neck_z + dz, bc_type=((1, 0.0), (1, 0.0)))
        # The shirt's collar sits round the neck itself, only a little lower at the throat.
        if self.female:
            dz = np.array([-0.022, -0.014, 0.0, 0.012, 0.012, 0.004, -0.004])
        else:
            dz = np.array([-0.032, -0.028, 0.008, 0.045, 0.045, 0.03, 0.024])
        self._shirt_line = CubicSpline(at, b.neck_z + dz, bc_type=((1, 0.0), (1, 0.0)))

    def neckline(self, phi):
        """Where the jacket meets the neck, by angle round it (0 at the front)."""
        a = np.abs((np.asarray(phi) + np.pi) % (2 * np.pi) - np.pi)
        return self._neckline(a)

    def shirt_line(self, phi):
        """The bottom of the shirt's collar, by angle round the neck."""
        a = np.abs((np.asarray(phi) + np.pi) % (2 * np.pi) - np.pi)
        return self._shirt_line(a)

    def collar_cut(self, p):
        """Above zero where the jacket's shell is cut away for the collar: under the neckline, and
        further under it at the back, where the collar falls over the edge. Away from the neck the
        line climbs, so the shoulders are kept."""
        dx, dy = p[0], p[1] - self.neck_y
        phi = math.atan2(dx, -dy)
        drop = 0.006 + 0.026 * max(0.0, -math.cos(phi)) ** 1.5
        return p[2] - (float(self.neckline(phi)) - drop) - 2.0 * max(0.0, math.hypot(dx, dy) - 0.17)

    def shirt_cut(self, p):
        """Above zero where the shirt's front is cut away: well up inside its collar, so the
        two overlap however the neck turns."""
        dx, dy = p[0], p[1] - self.neck_y
        return p[2] - (float(self.shirt_line(math.atan2(dx, -dy))) + 0.028)


def v_planes(s):
    """The two planes of the jacket's V: (point, normal) pairs whose normals point into the V."""
    out = []
    for side in (1.0, -1.0):
        pb = np.array([0.0, 0.0, s.z_button])
        pg = np.array([side * s.x_gorge, 0.0, s.z_gorge])
        n = side * np.cross(pg - pb, [0.0, 1.0, 0.0])
        out.append((pb, n / np.linalg.norm(n)))
    return out


def in_v(s, P):
    (p1, n1), (p2, n2) = v_planes(s)
    P = np.atleast_2d(P)
    return ((P - p1) @ n1 > 0) & ((P - p2) @ n2 > 0) & (P[:, 1] < 0.02) & (P[:, 2] > s.z_button - 1e-4)


def jacket_shell(body, s, F):
    """The jacket over the chest, back, shoulders and arms (its skirt is separate)."""
    c = body.co
    keep = ((c[:, 2] > s.z_cut - 0.08) & (body.w_head < 0.4) & (body.w_hand < 0.6)
            & (np.abs(c[:, 0]) < s.sleeve + 0.08) & (body.w_leg < 0.5))
    bm = body_piece(body, keep)
    cut(bm, (0, 0, s.z_cut), (0, 0, -1))
    cut(bm, (s.sleeve, 0, 0), (1, 0, 0))
    cut(bm, (-s.sleeve, 0, 0), (-1, 0, 0))
    subdivide(bm)
    set_coords(bm, F.onto(coords(bm), s.R_jacket, s.ease_jacket))
    settle(bm, F, s.R_jacket, s.ease_jacket)
    P = coords(bm)
    for side in (1, -1):
        a = body.shoulder * [side, 1, 1]
        b = body.hand * [side, 1, 1]
        P = drape(P, P[:, 0] * side > abs(a[0]) + 0.02, a, b, taper=0.09, t0=0.06)
    set_coords(bm, P)
    smooth(bm, 8)
    P = F.onto(coords(bm), s.R_jacket, s.ease_jacket * 0.8, outward_only=True)
    set_coords(bm, P)
    # The neckline: the collar lies over the edge from here, lower at the back where it falls.
    edge = cut_level(bm, s.collar_cut)
    E = np.array([v.co[:] for v in edge])
    phi = np.arctan2(E[:, 0], -(E[:, 1] - s.neck_y)) % (2 * np.pi)
    order = np.argsort(phi)
    s.collar_edge = (phi[order], E[order])
    # The cut lines stay where they were cut.
    for e in bm.edges:
        if e.is_boundary:
            for v in e.verts:
                if abs(v.co.z - s.z_cut) < 0.03 and abs(v.co.x) < 0.3:
                    v.co.z = s.z_cut
                elif abs(abs(v.co.x) - s.sleeve) < 0.03:
                    v.co.x = math.copysign(s.sleeve, v.co.x)
    if s.female:
        # The waist edge runs smoothly round, and lies on the skirt below it, so the join
        # reads as a seam rather than a step.
        bm.verts.ensure_lookup_table()
        waist = np.array([v.is_boundary and abs(v.co.z - s.z_cut) < 1e-4 for v in bm.verts])
        smooth(bm, 8, pin=~waist)
        P = coords(bm)
        P[waist] = F.onto(P[waist], s.R_jacket, s.ease_jacket - 0.004)
        P[waist, 2] = s.z_cut
        set_coords(bm, P)
    return bm


def open_v(bm, s):
    """Cuts the V at the front of the jacket, where the shirt and tie show."""
    for co, no in v_planes(s):
        geom = [f for f in bm.faces if f.calc_center_median().y < 0.02 and f.calc_center_median().z > s.z_button - 0.03]
        verts = list({v for f in geom for v in f.verts})
        edges = list({e for f in geom for e in f.edges})
        bmesh.ops.bisect_plane(bm, geom=verts + edges + geom, dist=1e-6, plane_co=Vector(co), plane_no=Vector(no))
    kill = [f for f in bm.faces if in_v(s, np.array(f.calc_center_median()))[0]]
    bmesh.ops.delete(bm, geom=kill, context='FACES')
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context='VERTS')


def sleeve_hems(bm, body, s):
    """Turns the sleeve ends in a little, so they read as cloth with a thickness."""
    bm.verts.ensure_lookup_table()
    for side in (1, -1):
        loop = [e for e in bm.edges if e.is_boundary and all(abs(v.co.x - side * s.sleeve) < 0.001 for v in e.verts)]
        verts = list({v for e in loop for v in e.verts})
        axis_y, axis_z = body.hand[1], body.hand[2]
        ret = bmesh.ops.extrude_edge_only(bm, edges=loop)
        new = [g for g in ret["geom"] if isinstance(g, bmesh.types.BMVert)]
        for v in new:
            r = Vector((0, v.co.y - axis_y, v.co.z - axis_z))
            v.co -= r.normalized() * 0.006
            v.co.x -= side * 0.012


def skirt(body, s, F):
    """The jacket below the waist: hangs from the hips over the seat, open at the front below the
    lower button, with a little flare. Its top tucks inside the shell."""
    cy = 0.5 * (body.co[np.abs(body.co[:, 2] - s.z_cut) < 0.02][:, 1].min() + body.co[np.abs(body.co[:, 2] - s.z_cut) < 0.02][:, 1].max())
    center = lambda z: np.array([0.0, cy, z])
    rows = np.linspace(s.z_skirt, s.z_hem, 12)
    cols = 56
    gap_hem = 0.065
    bm = bmesh.new()
    vrows = []
    prev = None
    for z in rows:
        depth = (s.z_split - z) / (s.z_split - s.z_hem)
        gap = gap_hem * max(depth, 0.0) ** 1.4
        # The front edges' angle: the gap measured round the front.
        g = gap / 0.13
        alpha = np.linspace(g + 1e-3, 2 * np.pi - g - 1e-3, cols)
        dirs = np.stack([np.sin(alpha), -np.cos(alpha), np.zeros(cols)], 1)
        cs = np.repeat(center(z)[None], cols, 0)
        if z > s.z_cut - 0.004:
            r = F.reach(cs, dirs, s.R_jacket, s.ease_jacket) - 0.004
        else:
            r = F.reach(cs, dirs, s.R_skirt, s.ease_skirt)
            blend = np.clip((s.z_cut - z) / s.skirt_blend, 0, 1)
            rj = F.reach(cs, dirs, s.R_jacket, s.ease_jacket)
            r = rj + (r - rj) * blend
        flare = 0.012 * np.clip((s.z_cut - z) / (s.z_cut - s.z_hem), 0, 1)
        r = r + flare
        if prev is not None and z < s.z_cut:
            r = np.maximum(r, prev - 0.01)
        prev = r
        vrows.append(new_verts(bm, cs + dirs * r[:, None]))
    grid_faces(bm, vrows, flip=True)
    recalc(bm)
    bm = solidify(bm, 0.005)
    return bm, cy


def pocket_flaps(skirt_bvh, s, cy):
    """Flaps over the hip pockets, standing a little off the skirt."""
    bm = bmesh.new()
    for side in (1, -1):
        rows = []
        for z in (s.z_hem + 0.13, s.z_hem + 0.08):
            row = []
            for x in np.linspace(*s.flap_x, 6):
                p, n = hit(skirt_bvh, (side * x, -0.6, z), (0, 1, 0))
                if p is None:
                    continue
                row.append(p + n * 0.003)
            rows.append(row)
        if len(rows[0]) == len(rows[1]) and len(rows[0]) > 1:
            grid_faces(bm, [new_verts(bm, r) for r in rows], flip=side < 0)
    recalc(bm)
    return solidify(bm, 0.004)


def lapels_and_collar(body, s, F, jacket_bvh):
    """The lapels fold back from the V's edges; the collar wraps the back of the neck."""
    bm = bmesh.new()
    rims = bmesh.new()
    steps = np.linspace(0.0, 1.0, 16)
    tops = {}
    for side in (1, -1):
        rows = []
        rim_rows = [[], []]
        for t in steps:
            e = np.array([side * s.x_gorge * t, -0.6, s.z_button + (s.z_gorge - s.z_button) * t])
            pe, ne = hit(jacket_bvh, e, (0, 1, 0))
            if pe is None:
                continue
            w = 0.082 * math.sin(math.pi * 0.5 * min(t / 0.85, 1.0)) ** 0.85
            out = np.array([side * 0.36, 0.0, -0.075 * 1.0])
            out /= np.linalg.norm(out)
            row = []
            for k, f in enumerate((0.0, 0.5, 1.0)):
                q = pe + out * w * f
                pq, nq = hit(jacket_bvh, (q[0], -0.6, q[2]), (0, 1, 0))
                if pq is None:
                    pq, nq = pe, ne
                lift = 0.004 + 0.003 * math.sin(math.pi * f)
                row.append(pq + nq * lift)
            rows.append(row)
            rim_rows[0].append(row[0])
            rim_rows[1].append(pe - ne * 0.012)
        grid = [new_verts(bm, r) for r in rows]
        grid_faces(bm, grid, flip=side > 0)
        # The edge of the V: a strip down behind it, over the gap to the shirt.
        rim = [new_verts(rims, r) for r in rim_rows]
        grid_faces(rims, [rim[0], rim[1]], flip=side < 0)
        tops[side] = (rows[-1][0], rows[-1][-1])
    recalc(bm)
    lap = solidify(bm, 0.003)
    # The collar: from the jacket's edge up to the fold round the neck, and a little way back
    # down inside it, over the shirt's collar.
    front_y = body.co[(np.abs(body.co[:, 2] - s.z_gorge) < 0.01) & (np.abs(body.co[:, 0]) < 0.02)][:, 1].min()
    phi_g = math.atan2(s.x_gorge, s.neck_y - front_y)
    phis = np.linspace(phi_g, 2 * np.pi - phi_g, 48)
    dirs = np.stack([np.sin(phis), -np.cos(phis), np.zeros(len(phis))], 1)
    ephi, E = s.collar_edge
    fall = np.stack([np.interp(phis, ephi, E[:, k], period=2 * np.pi) for k in range(3)], 1)
    fall += dirs * 0.002
    back = ((1 - np.cos(phis)) * 0.5) ** 0.5
    top = np.array([neck_ring_at(body, s, [phi], 0.014 + 0.014 * k, 0.021)[0] for phi, k in zip(phis, back)])
    base = np.array([neck_ring_at(body, s, [phi], -0.004, 0.019)[0] for phi in phis])
    for ring in (fall, top, base):
        for _ in range(2):
            ring[1:-1] = 0.25 * ring[:-2] + 0.5 * ring[1:-1] + 0.25 * ring[2:]
    col = bmesh.new()
    grid_faces(col, [new_verts(col, base), new_verts(col, top), new_verts(col, fall)])
    recalc(col)
    col = solidify(col, 0.003, even=False)
    return [lap, rims, col]


def shirt(body, s, F):
    """The shirt where it shows: its front in the V, the collar and the cuffs."""
    c = body.co
    parts = []
    keep = (c[:, 1] < 0.03) & (c[:, 2] > s.z_button - 0.06) & (np.abs(c[:, 0]) < s.shirt_x + 0.02) & (body.w_head < 0.7) & (body.w_hand < 0.1)
    bm = body_piece(body, keep)
    cut(bm, (0, 0, s.z_button - 0.05), (0, 0, -1))
    if s.female:
        # Its sides cut cleanly, since some of them show at the sides of the neck.
        cut_level(bm, lambda p: abs(p[0]) - s.shirt_x)
    subdivide(bm)
    set_coords(bm, F.onto(coords(bm), s.R_shirt, s.ease_shirt))
    settle(bm, F, s.R_shirt, s.ease_shirt)
    set_coords(bm, F.onto(coords(bm), s.R_shirt, s.ease_shirt * 0.8, outward_only=True))
    cut_level(bm, s.shirt_cut)
    # Its top tucks in close to the skin, behind the collar, so it stays there as the neck bends.
    P = coords(bm)
    phi = np.arctan2(P[:, 0], -(P[:, 1] - s.neck_y))
    t = np.clip((P[:, 2] - (s.shirt_line(phi) - 0.05)) / 0.05, 0.0, 1.0)[:, None]
    set_coords(bm, P * (1 - t) + F.onto(P, s.R_shirt, 0.001) * t)
    parts.append(bm)
    # The collar: a band round the neck, closed at the throat behind the knot, its points
    # dipping down the front either side of it.
    phi_t = math.radians(3)
    phis = np.linspace(phi_t, 2 * np.pi - phi_t, 44)
    rows = [neck_ring_at(body, s, phis, -0.004, 0.012, s.shirt_line), neck_ring_at(body, s, phis, s.collar_h, 0.014, s.shirt_line)]
    front = np.minimum(np.abs(phis), np.abs(2 * np.pi - phis))
    dip = np.clip(1 - (front - phi_t) / math.radians(34), 0, 1) ** 1.5
    low = rows[0].copy()
    low[:, 2] -= s.collar_dip * dip
    low = F.onto(low, s.R_shirt, s.ease_shirt + 0.004, outward_only=True)
    rows[0] = low
    # Its inside, turned down from the top edge, so the neck doesn't show past it.
    rows.append(neck_ring_at(body, s, phis, s.collar_h - 0.015, 0.003, s.shirt_line))
    rows.append(neck_ring_at(body, s, phis, 0.0, 0.0, s.shirt_line))
    col = bmesh.new()
    grid_faces(col, [new_verts(col, r) for r in rows])
    recalc(col)
    parts.append(solidify(col, 0.0025, even=False))
    # The cuffs.
    cuffs = bmesh.new()
    for side in (1, -1):
        rings = []
        for x in (s.sleeve - 0.03, s.cuff):
            ang = np.linspace(0, 2 * np.pi, 20, endpoint=False)
            dirs = np.stack([np.zeros(20), np.cos(ang), np.sin(ang)], 1)
            cs = np.repeat(np.array([[side * x, body.hand[1], body.hand[2]]]), 20, 0)
            r = F.reach(cs, dirs, 0.02, 0.006, far=0.15)
            rings.append(new_verts(cuffs, cs + dirs * r[:, None]))
        grid_faces(cuffs, rings, closed=True, flip=side > 0)
    recalc(cuffs)
    parts.append(cuffs)
    return parts


def tie(body, s, shirt_bvh):
    """A tie: a knot at the throat where the collar closes, and the blade down the shirt."""
    bm = bmesh.new()
    z0 = float(s.shirt_line(0.0))
    zk_top, zk_bot = z0 + 0.038, z0 - 0.014
    # Over a bust the blade bends, so it has more rows there, lifted straight forward rather
    # than along the shirt's faces.
    zs = np.linspace(zk_bot + 0.004, s.z_button - 0.06, 30 if s.female else 14)
    rows = []
    for z in zs:
        f = (zk_bot - z) / (s.z_gorge - s.z_button)
        half = 0.012 + 0.031 * min(max(f, 0.0), 1.0) ** 0.8
        row = []
        for x, lift in ((-half, 0.003), (0.0, 0.0055), (half, 0.003)):
            p, n = hit(shirt_bvh, (x, -0.6, z), (0, 1, 0))
            if p is None:
                p, n = np.array([x, -0.1, z]), FWD
            row.append(p + (FWD if s.female else n) * lift)
        rows.append(row)
    grid_faces(bm, [new_verts(bm, r) for r in rows], flip=True)
    # The knot, a little proud of the collar's front.
    pts = []
    for z, half in ((zk_top, 0.018), (zk_bot, 0.011)):
        front = neck_round(body, s.neck_y, z, [0.0], 0.0)[0]
        for x in (-half, half):
            pts.append((np.array([x, front[1] - 0.002, z]), np.array([x, front[1] - 0.024, z])))
    (a0, a1), (b0, b1), (c0, c1), (d0, d1) = pts
    vs = new_verts(bm, [a0, b0, d0, c0, a1, b1, d1, c1])
    for q in ((0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)):
        bm.faces.new([vs[i] for i in q])
    recalc(bm)
    return solidify(bm, 0.002)


def trousers(body, s):
    """Trousers from the waist to a hem that breaks over the shoes, hanging straight."""
    c = body.co
    legs = (body.w_leg > 0.2) | (body.w_pelvis > 0.2) | (body.w_foot > 0.2)
    F = Field(body.triangles(legs & (c[:, 2] < s.z_trousers + 0.1)))
    keep = (c[:, 2] < s.z_trousers + 0.05) & (c[:, 2] > s.z_ankle - 0.04) & (body.w_foot < 0.5) & (body.w_head < 0.1) & (body.w_hand < 0.1)
    keep &= np.abs(c[:, 0]) < 0.35
    bm = body_piece(body, keep)
    cut(bm, (0, 0, s.z_trousers), (0, 0, 1))
    cut(bm, (0, 0, s.z_ankle), (0, 0, -1))
    subdivide(bm)
    set_coords(bm, F.onto(coords(bm), s.R_trousers, s.ease_trousers))
    settle(bm, F, s.R_trousers, s.ease_trousers)
    P = coords(bm)
    for side in (1, -1):
        a = body.hip * [side, 1, 1]
        b = body.ankle * [side, 1, 1]
        P = drape(P, P[:, 0] * side > 0.025, a, b, taper=s.trouser_taper, t0=0.14)
    set_coords(bm, P)
    smooth(bm, 8)
    P = F.onto(coords(bm), s.R_trousers, s.ease_trousers * 0.7, outward_only=True)
    set_coords(bm, P)
    # The hem: down from the cut, longer at the back, a little wider (the break).
    bm.verts.ensure_lookup_table()
    loop = [e for e in bm.edges if e.is_boundary and all(v.co.z < s.z_ankle + 0.05 for v in e.verts)]
    for e in loop:
        for v in e.verts:
            v.co.z = s.z_ankle
    ret = bmesh.ops.extrude_edge_only(bm, edges=loop)
    hem = [g for g in ret["geom"] if isinstance(g, bmesh.types.BMVert)]
    for v in hem:
        side = 1 if v.co.x > 0 else -1
        ax = body.ankle * [side, 1, 1]
        r = Vector((v.co.x - ax[0], v.co.y - ax[1], 0))
        back = max(min((v.co.y - ax[1]) / 0.06, 1.0), -1.0)
        v.co += r.normalized() * 0.005
        v.co.z = body.floor + 0.07 - 0.02 * back
    ret = bmesh.ops.extrude_edge_only(bm, edges=[e for e in bm.edges if e.is_boundary and all(v in hem for v in e.verts)])
    for g in ret["geom"]:
        if isinstance(g, bmesh.types.BMVert):
            side = 1 if g.co.x > 0 else -1
            ax = body.ankle * [side, 1, 1]
            r = Vector((g.co.x - ax[0], g.co.y - ax[1], 0))
            g.co -= r.normalized() * 0.006
            g.co.z += 0.015
    recalc(bm)
    return bm, F


def iso_surface(F, R, ease, below):
    """The cloth surface itself, as a mesh, below a height (left open there)."""
    from skimage import measure
    E, _ = F.closing(R)
    vol = E - (R - ease)
    zi = int(math.ceil((below - F.lo[2]) / F.h))
    vol = vol.copy()
    vol[:, :, zi:] = -1.0
    verts, faces, _n, _v = measure.marching_cubes(vol, 0.0, spacing=(F.h, F.h, F.h))
    verts += F.lo
    bm = bmesh.new()
    vs = new_verts(bm, verts)
    for f in faces:
        try:
            bm.faces.new([vs[i] for i in f])
        except ValueError:
            pass
    cap = [f for f in bm.faces if all(v.co.z > below - F.h * 1.6 for v in f.verts)]
    bmesh.ops.delete(bm, geom=cap, context='FACES')
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context='VERTS')
    recalc(bm)
    return bm


def decimate(bm, ratio):
    me = bpy.data.meshes.new("tmp")
    bm.to_mesh(me)
    ob = bpy.data.objects.new("tmp", me)
    bpy.context.scene.collection.objects.link(ob)
    m = ob.modifiers.new("dec", 'DECIMATE')
    m.ratio = ratio
    dg = bpy.context.evaluated_depsgraph_get()
    me2 = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    out = bmesh.new()
    out.from_mesh(me2)
    bpy.data.objects.remove(ob)
    bpy.data.meshes.remove(me)
    bpy.data.meshes.remove(me2)
    return out


def shoes(body, s, point=0.0):
    """Plain black shoes over the feet: a rounded toe a little longer than the foot, a flat sole.
    Made from the cloth surface of the feet itself, so toes don't show through. With point, the
    toe is longer and narrows to a point (women's shoes)."""
    c = body.co
    feet = (body.w_foot > 0.2) | (c[:, 2] < 0.16)
    F = Field(body.triangles(feet & (np.abs(c[:, 0]) > 0.02)), h=0.003)
    bm = iso_surface(F, 0.045, 0.006, s.z_ankle + 0.008)
    bm = decimate(bm, 0.12)
    P = coords(bm)
    toe_y = c[c[:, 2] < 0.03][:, 1].min()
    front = np.clip((-0.05 - P[:, 1]) / (-0.05 - toe_y), 0, 1)
    P[:, 1] -= 0.014 * front ** 1.5
    if point:
        P[:, 1] -= point * front ** 2.5
        for side in (1, -1):
            m = P[:, 0] * side > 0
            cx = body.ankle[0] * side - side * 0.006
            P[m, 0] = cx + (P[m, 0] - cx) * (1.0 - 0.4 * front[m] ** 2)
    low = P[:, 2] < body.floor + 0.016
    for side in (1, -1):
        m = (P[:, 0] * side > 0)
        cx = body.ankle[0] * side
        P[m & low, 0] += np.sign(P[m & low, 0] - cx) * 0.002
    P[:, 2] = np.maximum(P[:, 2], body.floor)
    set_coords(bm, P)
    smooth(bm, 4)
    P = coords(bm)
    P[:, 2] = np.maximum(P[:, 2], body.floor)
    P[P[:, 2] < body.floor + 0.003, 2] = body.floor
    set_coords(bm, P)
    recalc(bm)
    return bm


def buttons_and_pin(body, s, jacket_bvh, skirt_bvh, lapel_bvh):
    buttons = bmesh.new()
    for z, bvh in ((s.z_button, jacket_bvh), (s.z_split + 0.012, skirt_bvh)):
        p, n = hit(bvh, (0.0, -0.6, z), (0, 1, 0))
        if p is not None:
            disc(buttons, p, n, 0.0105, 0.004, 16)
    # Three on each cuff, on the back of the sleeve.
    for side in (1, -1):
        for k in range(3):
            x = side * (s.sleeve - 0.025 - k * 0.017)
            p, n = hit(jacket_bvh, (x, body.hand[1], body.hand[2] + 0.2), (0, 0, -1))
            if p is not None:
                q, m = hit(jacket_bvh, (x, body.hand[1] + 0.2, body.hand[2] + 0.012), (0, -1, 0))
                if q is not None:
                    disc(buttons, q, m, 0.0055, 0.003, 10)
    pin = bmesh.new()
    t = s.pin_t
    x = s.x_gorge * t + 0.032
    z = s.z_button + (s.z_gorge - s.z_button) * t - 0.004
    p, n = hit(lapel_bvh, (x, -0.6, z), (0, 1, 0))
    if p is not None:
        disc(pin, p, n, 0.0085, 0.0025, 5, spin=math.pi / 2)
    return buttons, pin


def earpiece(body, F):
    """A bud in the left ear and a cable down behind it into the collar."""
    bud = bmesh.new()
    c = body.co
    ear = c[(c[:, 2] > 1.6) & (c[:, 2] < 1.76) & (c[:, 0] > 0.05)]
    ex = ear[np.argmax(ear[:, 0])]
    p = np.array([ex[0] - 0.006, ex[1] - 0.012, ex[2] - 0.022])
    p = F.push_out([p], 0.003)[0]
    bmesh.ops.create_uvsphere(bud, u_segments=10, v_segments=6, radius=0.0065, matrix=Matrix.Translation(Vector(p)))
    path = [p + [0.004, 0.006, -0.006], p + [0.008, 0.016, -0.03], p + [0.002, 0.03, -0.08],
            p + [-0.012, 0.045, -0.15], p + [-0.022, 0.05, -0.21]]
    path = F.push_out(path, 0.005)
    tube(bud, [p] + list(path), 0.0022)
    recalc(bud)
    return bud


# --- The evening dress -------------------------------------------------------------------------

def smoothstep(e0, e1, x):
    t = np.clip((np.asarray(x, float) - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


class Gown:
    """The evening dress's measurements, from the (female) body's bones. Angles go round the
    torso from the front (0) to the back (180)."""

    def __init__(self, body):
        b = body
        self.z_waist = b.pelvis_z + 0.2           # the bodice ends here and the skirt starts
        self.z_hip = b.pelvis_z - 0.05            # the skirt falls straight from below the hips
        self.z_shin = b.floor + 0.16              # leg skin is kept below this, for when it shows
        self.floor = b.floor
        self.R_bodice, self.ease_bodice = 0.03, 0.004
        self.R_skirt, self.ease_skirt = 0.07, 0.01
        self.x_strap, self.w_strap = 0.112, 0.024  # the straps over the shoulders
        self.z_v = b.neck_z - 0.215               # the bottom of the V at the front
        self.z_scoop = b.neck_z - 0.27            # and of the scoop at the back
        c = b.co
        near = (np.abs(c[:, 2] - b.neck_z) < 0.02) & (np.abs(c[:, 0]) < 0.09)
        self.neck_y = 0.5 * (c[near][:, 1].min() + c[near][:, 1].max())
        near = (np.abs(c[:, 2] - (b.neck_z - 0.18)) < 0.02) & (np.abs(c[:, 0]) < 0.05)
        self.cy = 0.5 * (c[near][:, 1].min() + c[near][:, 1].max())
        # Where the straps meet the bodice at the front and back, and the armholes between, by
        # angle round the torso: from the straps' outer edges, down under the arms.
        self.z_strap_front = b.neck_z - 0.09
        self.z_strap_back = b.neck_z - 0.1
        x = self.x_strap + 0.5 * self.w_strap
        pf, _n = hit(b.bvh, (x, -0.6, self.z_strap_front), (0, 1, 0))
        pb, _n = hit(b.bvh, (x, 0.6, self.z_strap_back), (0, -1, 0))
        self.a_front = math.atan2(x, -(pf[1] - self.cy))
        self.a_back = math.atan2(x, -(pb[1] - self.cy))
        self.z_side = b.neck_z - 0.175
        # The necklace round the base of the neck, falling to the top of the chest.
        z = b.neck_z + np.array([-0.105, -0.07, -0.02, -0.004, -0.012, -0.035, -0.045])
        self._chain = CubicSpline(np.radians([0, 30, 60, 90, 120, 150, 180]), z, bc_type=((1, 0.0), (1, 0.0)))

    def angle(self, p):
        return abs(math.atan2(p[0], -(p[1] - self.cy)))

    def neckline(self, p):
        """Above zero where the bodice is cut away: over the V at the front, the scoop at the
        back and the armholes, except along the straps."""
        x = abs(p[0])
        front = p[1] < self.cy
        if x < self.x_strap:
            t = x / self.x_strap
            if front:
                top = self.z_v + (self.z_strap_front - self.z_v) * t ** 1.15
            else:
                top = self.z_scoop + (self.z_strap_back - self.z_scoop) * t ** 2.2
            g = p[2] - top
        else:
            g = p[2] - self.armhole(self.angle(p))
        strap = abs(x - self.x_strap) - 0.5 * self.w_strap
        # A soft minimum, so the straps run into the neckline and armholes with rounded corners.
        k = 0.015
        h = max(k - abs(g - strap), 0.0) / k
        return min(g, strap) - h * h * k * 0.25

    def armhole(self, a):
        """The armhole's height by angle round the torso: steeply down from the strap's outer
        edge, round under the arm and up to the back strap; above the straps beyond them."""
        side = 0.5 * math.pi
        if a < self.a_front:
            return self.z_strap_front + (self.a_front - a) * 0.4
        if a > self.a_back:
            return self.z_strap_back + (a - self.a_back) * 0.4
        if a < side:
            u = (a - self.a_front) / (side - self.a_front)
            return self.z_side + (self.z_strap_front - self.z_side) * (1 - u) ** 1.8
        u = (self.a_back - a) / (self.a_back - side)
        return self.z_side + (self.z_strap_back - self.z_side) * (1 - u) ** 1.8

    def chain_line(self, phi):
        a = np.abs((np.asarray(phi) + np.pi) % (2 * np.pi) - np.pi)
        return self._chain(a)


def bodice(body, gw, F):
    """The bodice: fitted over the bust and waist, cut to a V at the front, a low scoop at the
    back and armholes, with straps over the shoulders. Its edges hug the skin."""
    c = body.co
    w_arm = sum(body.W[:, body.group(n)] for n in ("upperarm_l", "upperarm_r", "lowerarm_l", "lowerarm_r"))
    keep = ((c[:, 2] > gw.z_waist - 0.06) & (body.w_head < 0.4) & (body.w_hand < 0.1) & (body.w_leg < 0.5)
            & ((w_arm < 0.5) | (np.abs(c[:, 0]) < gw.x_strap + 0.03)))
    bm = body_piece(body, keep)
    cut(bm, (0, 0, gw.z_waist), (0, 0, -1))
    # Keep only what's near the dress (the straps and below the neckline) before refining.
    bm.verts.ensure_lookup_table()
    far = [f for f in bm.faces if min(gw.neckline(np.array(v.co[:])) for v in f.verts) > 0.03]
    bmesh.ops.delete(bm, geom=far, context='FACES')
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    subdivide(bm, 2)
    set_coords(bm, F.onto(coords(bm), gw.R_bodice, gw.ease_bodice))
    settle(bm, F, gw.R_bodice, gw.ease_bodice, rounds=6)
    smooth(bm, 6)
    # Thinned to what a gala full of guests can afford, before the cut so its edges stay clean.
    bm = decimate(bm, 0.3)
    smooth(bm, 3)
    set_coords(bm, F.onto(coords(bm), gw.R_bodice, gw.ease_bodice * 0.8, outward_only=True))
    cut_level(bm, gw.neckline)
    # The cut edges smoothed along themselves (the cut crosses uneven faces), then the rest.
    bm.verts.ensure_lookup_table()
    edge = np.array([v.is_boundary and v.co.z > gw.z_waist + 0.01 for v in bm.verts])
    for _ in range(3):
        smooth(bm, 6, pin=~edge)
        P = coords(bm)
        P[edge] = F.onto(P[edge], gw.R_bodice, gw.ease_bodice)
        set_coords(bm, P)
    smooth(bm, 3, pin=edge)
    # Its edges hug the skin, so the neckline sits on the chest and the straps on the shoulders.
    P = coords(bm)
    g = np.array([gw.neckline(p) for p in P])
    t = np.clip(1.0 + g / 0.025, 0.0, 1.0)[:, None] * (P[:, 2] > gw.z_waist + 0.05)[:, None]
    set_coords(bm, P * (1 - t) + F.onto(P, gw.R_bodice, 0.0015) * t)
    # Smoothed again so the edges don't follow the facets of the skin under them.
    smooth(bm, 4)
    set_coords(bm, F.onto(coords(bm), gw.R_bodice, 0.0015, outward_only=True))
    for v in bm.verts:
        if v.is_boundary and abs(v.co.z - gw.z_waist) < 0.004:
            v.co.z = gw.z_waist
    recalc(bm)
    return solidify(bm, 0.002, even=False)


def gown_skirt(body, gw, F, Fb):
    """The skirt: fitted over the hips, then falling straight to the floor with a little flare,
    more at the back. Its top tucks inside the bodice (whose cloth surface is Fb's)."""
    c = body.co
    near = (np.abs(c[:, 2] - gw.z_hip) < 0.02) & (np.abs(c[:, 0]) < 0.05)
    cy = 0.5 * (c[near][:, 1].min() + c[near][:, 1].max())
    cols = 96
    alpha = np.linspace(0, 2 * np.pi, cols, endpoint=False)
    dirs = np.stack([np.sin(alpha), -np.cos(alpha), np.zeros(cols)], 1)
    back = (1 - np.cos(alpha)) * 0.5
    z_top = gw.z_waist + 0.008
    hem = gw.floor + 0.03 - 0.022 * back
    # Rows close together over the hips, further apart down the fall.
    u = np.linspace(0.0, 1.0, 38) ** 1.6
    bm = bmesh.new()
    vrows = []
    prev = None
    for k, uk in enumerate(u):
        z = z_top + (hem - z_top) * uk
        cs = np.stack([np.zeros(cols), np.full(cols, cy), z], 1)
        if prev is None or z.mean() > gw.z_waist - 0.07:
            rb = Fb.reach(cs, dirs, gw.R_bodice, gw.ease_bodice, miss=0.0)
            rs = F.reach(cs, dirs, gw.R_skirt, gw.ease_skirt, miss=0.0)
            blend = np.clip((gw.z_waist - 0.02 - z) / 0.05, 0, 1)
            r = rb - 0.005 * (1 - blend) + (rs - rb) * blend
        else:
            r = F.reach(cs, dirs, gw.R_skirt, gw.ease_skirt, miss=0.0)
            r = np.maximum(r, prev)
        fall = np.clip((gw.z_hip - z) / (gw.z_hip - gw.floor), 0, 1)
        flare = (0.045 + 0.03 * back ** 2) * fall ** 1.5
        rr = r + flare
        for _ in range(3):
            rr = 0.25 * np.roll(rr, 1) + 0.5 * rr + 0.25 * np.roll(rr, -1)
        if prev is not None:
            r = np.maximum(r, prev)
        prev = r
        vrows.append(new_verts(bm, cs + dirs * rr[:, None]))
    grid_faces(bm, vrows, closed=True, flip=True)
    recalc(bm)
    smooth(bm, 4)
    return solidify(bm, 0.003, even=False)


def waistband(body, gw, F):
    """A narrow band at the waist over the join of the bodice and the skirt."""
    c = body.co
    cols = 120
    alpha = np.linspace(0, 2 * np.pi, cols, endpoint=False)
    dirs = np.stack([np.sin(alpha), -np.cos(alpha), np.zeros(cols)], 1)
    bm = bmesh.new()
    rows = []
    for z in (gw.z_waist - 0.016, gw.z_waist + 0.014):
        near = (np.abs(c[:, 2] - z) < 0.02) & (np.abs(c[:, 0]) < 0.05)
        cy = 0.5 * (c[near][:, 1].min() + c[near][:, 1].max())
        cs = np.stack([np.zeros(cols), np.full(cols, cy), np.full(cols, z)], 1)
        r = F.reach(cs, dirs, gw.R_bodice, gw.ease_bodice) + 0.004
        for _ in range(4):
            r = 0.25 * np.roll(r, 1) + 0.5 * r + 0.25 * np.roll(r, -1)
        rows.append(new_verts(bm, cs + dirs * r[:, None]))
    grid_faces(bm, rows, closed=True, flip=True)
    recalc(bm)
    return solidify(bm, 0.003, even=False)


def necklace(body, gw):
    """A fine chain round the base of the neck with a drop at the front."""
    bm = bmesh.new()
    phis = np.linspace(0, 2 * np.pi, 96, endpoint=False)
    pts = neck_ring(body, phis, gw.chain_line(phis), 0.0)
    # Smoothed along its length and laid back on the skin, a few times.
    for _ in range(4):
        for _ in range(4):
            pts = 0.25 * np.roll(pts, 1, 0) + 0.5 * pts + 0.25 * np.roll(pts, -1, 0)
        for i, p in enumerate(pts):
            loc, n, _i, _d = body.bvh.find_nearest(Vector(p))
            pts[i] = np.array(loc) + np.array(n) * 0.0032
    tube(bm, list(pts) + [pts[0]], 0.0017, segments=6)
    # The drop: a little teardrop hanging from the front of the chain, just off the skin.
    top = pts[0]
    p, n = hit(body.bvh, (0.0, -0.6, top[2] - 0.016), (0, 1, 0))
    drop = (p + n * 0.0065) if p is not None else top + np.array([0.0, -0.005, -0.016])
    tube(bm, [top, drop + np.array([0, 0, 0.007])], 0.0011, segments=5)
    bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=8, radius=0.0055,
                              matrix=Matrix.Translation(Vector(drop)) @ Matrix.Diagonal((1.0, 0.7, 1.35, 1.0)))
    recalc(bm)
    return bm


def gown_weights(body, gw):
    """The skirt follows the hips at the top and, further down, the legs: each side its own
    leg, blending across the middle, and towards the hem partly the shin, so a foot set back
    stays inside it."""
    pelvis = body.group("pelvis")
    tl, tr = body.group("thigh_l"), body.group("thigh_r")
    cl, cr = body.group("calf_l"), body.group("calf_r")
    knee = body.bone("calf_l")[2]

    def fn(P, W):
        W = W.copy()
        side = smoothstep(-0.07, 0.07, P[:, 0])
        leg = smoothstep(body.hip[2] + 0.04, body.hip[2] - 0.4, P[:, 2])
        shin = 0.65 * smoothstep(knee + 0.05, gw.floor + 0.1, P[:, 2])
        L = np.zeros_like(W)
        L[:, pelvis] = 1.0 - leg
        L[:, tl] = leg * side * (1 - shin)
        L[:, tr] = leg * (1.0 - side) * (1 - shin)
        L[:, cl] = leg * side * shin
        L[:, cr] = leg * (1.0 - side) * shin
        blend = smoothstep(gw.z_waist - 0.02, gw.z_waist - 0.14, P[:, 2])[:, None]
        return normalize_weights(W * (1 - blend) + L * blend)
    return fn


def evening_dress(body):
    gw = Gown(body)
    lower = bust_filler(body, z1=body.neck_z - 0.17)
    F = Field(np.concatenate([body.triangles(), lower]))
    # The bodice lies closer, on a finer field of the torso.
    box = (np.array([-0.32, -0.4, gw.z_waist - 0.2]), np.array([0.32, 0.4, body.neck_z + 0.15]))
    Fb = Field(np.concatenate([body.triangles(), lower]), h=0.004, box=box)
    top = bodice(body, gw, Fb)
    band = waistband(body, gw, Fb)
    sk = gown_skirt(body, gw, F, Fb)
    s = Suit(body)
    feet = shoes(body, s, point=0.02)
    chain = necklace(body, gw)
    # The skin under the dress goes, but not under its edges, or below the shins (it shows
    # under the hem as she walks).
    c = body.co
    g = np.array([gw.neckline(p) for p in c])
    # Skin in a hollow the bodice bridges stays: it shows down the V, and can't come through.
    inbox = np.all((c > box[0]) & (c < box[1]), axis=1)
    deep = np.zeros(len(c), bool)
    deep[inbox] = Fb.at(Fb.closing(gw.R_bodice)[0], c[inbox]) - gw.R_bodice > 0.008
    covered = (g < -0.015) & (c[:, 2] > gw.z_waist - 0.02) & ~deep
    covered |= (c[:, 2] < gw.z_waist) & (c[:, 2] > gw.z_shin) & (body.w_hand < 0.1)
    covered |= c[:, 2] < s.z_ankle - 0.01
    keep_skin(body, ~covered)
    add_part(body, "Dress", [top, band, sk], gown_weights(body, gw), smooth_weights=30)
    add_part(body, "Shoes", [feet])
    add_part(body, "Necklace", [chain])


# --- Putting it together -----------------------------------------------------------------------

def trim_body(body, s):
    """Cuts away the skin the clothes cover, keeping the head, the neck above the middle of the
    shirt's collar (so the skin can't show through the collar as the neck turns) and the hands."""
    c = body.co
    dx, dy = c[:, 0], c[:, 1] - s.neck_y
    neck = (c[:, 2] > s.shirt_line(np.arctan2(dx, -dy)) + 0.035) & (np.hypot(dx, dy) < 0.16)
    keep_skin(body, (np.abs(c[:, 0]) > s.skin_hand) | neck | ((body.w_head > 0.5) & (c[:, 2] > body.neck_z + 0.08)))


def keep_skin(body, keep):
    """Cuts away the body's faces with no corner in keep."""
    bm = bmesh.new()
    bm.from_mesh(body.obj.data)
    bm.verts.ensure_lookup_table()
    kill = [f for f in bm.faces if not any(keep[v.index] for v in f.verts)]
    bmesh.ops.delete(bm, geom=kill, context='FACES')
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context='VERTS')
    bm.to_mesh(body.obj.data)
    body.obj.name = "Body"


def add_part(body, name, bms, weights_fn=None, smooth_shade=True, smooth_weights=0):
    """One mesh from some bmeshes, skinned like the body under it. smooth_weights blurs the
    weights over the mesh that many times first, so cloth bridging a hollow (where the nearest
    skin jumps from one side to the other) doesn't tear as the body moves."""
    bm = bmesh.new()
    for b in bms:
        tmp = bpy.data.meshes.new("tmp")
        b.to_mesh(tmp)
        bm.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
    bm.verts.ensure_lookup_table()
    for layer in list(bm.verts.layers.deform):
        bm.verts.layers.deform.remove(layer)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    for g in body.groups:
        ob.vertex_groups.new(name=g)
    P = np.array([v.co[:] for v in me.vertices])
    W = body.weights(P)
    if smooth_weights:
        E = np.array([e.vertices[:] for e in me.edges])
        n = len(P)
        A = sparse.coo_matrix((np.ones(2 * len(E)), (np.r_[E[:, 0], E[:, 1]], np.r_[E[:, 1], E[:, 0]])), shape=(n, n)).tocsr()
        deg = np.maximum(np.asarray(A.sum(1)).ravel(), 1)[:, None]
        for _ in range(smooth_weights):
            W = 0.5 * W + 0.5 * (A @ W) / deg
        W = normalize_weights(W.astype(np.float32))
    if weights_fn:
        W = weights_fn(P, W)
    for gi in range(W.shape[1]):
        idx = np.nonzero(W[:, gi] > 1e-4)[0]
        vg = ob.vertex_groups[gi]
        for i in idx:
            vg.add([int(i)], float(W[i, gi]), 'REPLACE')
    if smooth_shade:
        for poly in me.polygons:
            poly.use_smooth = True
        if hasattr(me, "set_sharp_from_angle"):
            me.set_sharp_from_angle(angle=math.radians(75))
    ob.parent = body.arm
    m = ob.modifiers.new("Armature", 'ARMATURE')
    m.object = body.arm
    return ob


def skirt_weights(body, s):
    """The skirt follows the hips and only partly the legs, so it swings rather than splits."""
    pelvis = body.group("pelvis")
    legs = [body.group(n) for n in ("thigh_l", "thigh_r", "calf_l", "calf_r")]

    def fn(P, W):
        W = W.copy()
        below = np.clip((s.z_cut - P[:, 2]) / 0.06, 0, 1)
        moved = 0.0
        for g in legs:
            take = W[:, g] * 0.5 * below
            W[:, g] -= take
            moved = moved + take
        W[:, pelvis] += moved
        return normalize_weights(W)
    return fn


def head_weights(body, until):
    """The earpiece rides the head down to a height, then the neck."""
    head = body.group("Head")

    def fn(P, W):
        W = W.copy()
        m = P[:, 2] > until
        W[m] = 0.0
        W[m, head] = 1.0
        return W
    return fn


def halberd_suit(body):
    s = Suit(body)
    tris = body.triangles()
    if s.female:
        tris = np.concatenate([tris, bust_filler(body), seat_filler(body)])
    F = Field(tris)
    jac = jacket_shell(body, s, F)
    jacket_bvh = bvh_of(jac)
    open_v(jac, s)
    sleeve_hems(jac, body, s)
    recalc(jac)
    sk, cy = skirt(body, s, F)
    skirt_bvh = bvh_of(sk)
    flaps = pocket_flaps(skirt_bvh, s, cy)
    lapel_parts = lapels_and_collar(body, s, F, jacket_bvh)
    lapel_bvh = bvh_of(lapel_parts[0])
    tr, _ = trousers(body, s)
    sh = shirt(body, s, F)
    shirt_bvh = bvh_of(sh[0])
    tie_bm = tie(body, s, shirt_bvh)
    shoe_bm = shoes(body, s, point=0.012 if s.female else 0.0)
    buttons, pin = buttons_and_pin(body, s, jacket_bvh, skirt_bvh, lapel_bvh)
    ear = earpiece(body, F)
    trim_body(body, s)
    if os.environ.get("WARDROBE_PARTS"):
        for name, b in zip(("Jacket", "Lapels", "Rims", "Collar", "Flaps"), [jac] + lapel_parts + [flaps]):
            add_part(body, name, [b])
    else:
        add_part(body, "Suit", [jac] + lapel_parts + [flaps])
    add_part(body, "Skirt", [sk], skirt_weights(body, s))
    add_part(body, "Trousers", [tr])
    if os.environ.get("WARDROBE_PARTS"):
        for name, b in zip(("Shirt", "ShirtCollar", "Cuffs"), sh):
            add_part(body, name, [b])
    else:
        add_part(body, "Shirt", sh)
    add_part(body, "Tie", [tie_bm])
    add_part(body, "Shoes", [shoe_bm])
    add_part(body, "Buttons", [buttons], smooth_shade=False)
    add_part(body, "Pin", [pin], smooth_shade=False)
    add_part(body, "Earpiece", [ear], head_weights(body, body.neck_z + 0.07))


# Each outfit and the bodies it's made for.
OUTFITS = {"halberd_suit": (halberd_suit, ("male", "female")), "evening_dress": (evening_dress, ("female",))}


def export(body, path):
    bpy.ops.object.select_all(action='DESELECT')
    body.arm.select_set(True)
    for o in bpy.data.objects:
        if o.parent == body.arm:
            o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLTF_SEPARATE', use_selection=True,
                              export_animations=False, export_materials='NONE', export_skins=True,
                              export_morph=False, export_extras=False, export_vertex_color='NONE')


def main():
    os.makedirs(OUT, exist_ok=True)
    outfits = [o for o in OUTFITS if not (WANT & set(OUTFITS)) or o in WANT]
    bodies = [b for b in BODIES if not (WANT & set(BODIES)) or b in WANT]
    for outfit in outfits:
        make, fits = OUTFITS[outfit]
        for kind in [b for b in bodies if b in fits]:
            body = Body(kind)
            make(body)
            path = os.path.join(OUT, "%s_%s.gltf" % (outfit, kind))
            export(body, path)
            print("wrote", path)


if __name__ == "__main__":
    main()
