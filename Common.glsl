//=============================================================================
// Shadertoy 交互框架 - Common
//=============================================================================

#define PI acos(-1.)
#define TAU (2.0 * PI)
#define INF 1e10

//=============================================================================
// 【调试配置】
//=============================================================================

// 取消注释下面这行可以显示拾取几何体（调试用）
// #define DEBUG_SHOW_PICK_GEOMETRY

//=============================================================================
// 【用户配置区】
//=============================================================================

#define MAX_PICKABLE_COUNT 16
#define MAX_LIGHT_COUNT 8

#define ROW_MOUSE      0
#define ROW_SELECT     1
#define ROW_KEYS       2
#define ROW_COUNTS     3
#define ROW_OBJ_POS    4
#define ROW_OBJ_SCALE  5
#define ROW_OBJ_COLOR  6
#define ROW_OBJ_ROT0   7
#define ROW_OBJ_ROT1   8
#define ROW_OBJ_ROT2   9
#define ROW_LIGHT_POS  10
#define ROW_LIGHT_DIR  11
#define ROW_LIGHT_COL  12
#define ROW_LIGHT_PRM  13

const float fov  = 60.0;
const float near = 0.1;
const float far  = 100.0;
const vec3  INITIAL_CAM_POS = vec3(0.0, 0.0, -9.0);
const float MOUSE_SENSITIVITY_X = 10.0;
const float MOUSE_SENSITIVITY_Y = 5.0;
const float MOVE_SPEED = 0.8 / 30.0;
const float SPRINT_MULTIPLIER = 5.0;

const float ROTATE_SENSITIVITY = 3.0;
const float SCALE_SENSITIVITY = 3.0;
const float FOCUS_DISTANCE = 4.0;
const float FOCUS_SPEED = 0.08;

const vec3 ambientColor = vec3(0.08, 0.08, 0.1);

//=============================================================================
// 【线框配置】
//=============================================================================

// 拾取配置
const float PICK_LINE_RADIUS = 0.12;
const float PICK_BULB_RADIUS = 0.3;
const float PICK_CONE_HEIGHT = 0.8;
const float PICK_AREA_SCALE = 1.5;

// 视觉配置
const float VISUAL_BULB_RADIUS = 0.1;
const float VISUAL_CONE_HEIGHT = 0.3;
const float VISUAL_AREA_SCALE = 0.6;
const float LINE_WIDTH = 1.0;
const float LINE_WIDTH_SELECTED = 1.8;

// 线框颜色（固定，不受光照影响）
const vec3 GIZMO_COLOR = vec3(1.0, 0.92, 0.5);           // 淡黄色
const vec3 GIZMO_COLOR_SELECTED = vec3(1.0, 1.0, 0.7);   // 选中时更亮

//=============================================================================
// 常量
//=============================================================================

const float TRANSFORM_TRANSLATE = 1.0;
const float TRANSFORM_ROTATE    = 2.0;
const float TRANSFORM_SCALE     = 3.0;

const float MODE_NONE      = 0.0;
const float MODE_CAMERA    = 1.0;
const float MODE_TRANSFORM = 2.0;

const int KEY_W = 87;
const int KEY_A = 65;
const int KEY_S = 83;
const int KEY_D = 68;
const int KEY_E = 69;
const int KEY_R = 82;
const int KEY_F = 70;
const int KEY_V = 86;
const int KEY_SPACE = 32;
const int KEY_CTRL = 17;
const int KEY_SHIFT = 16;
const int KEY_DELETE = 46;

const float OBJ_TYPE_NONE   = -1.0;
const float OBJ_TYPE_SPHERE = 0.0;
const float OBJ_TYPE_BOX    = 1.0;

const float LIGHT_TYPE_NONE  = -1.0;
const float LIGHT_TYPE_POINT = 0.0;
const float LIGHT_TYPE_SPOT  = 1.0;
const float LIGHT_TYPE_AREA  = 2.0;

const float TARGET_OBJECT = 0.0;
const float TARGET_LIGHT  = 1.0;

#define UI_NONE 0
#define UI_ADD_SPHERE 1
#define UI_ADD_BOX 2
#define UI_ADD_POINT_LIGHT 3
#define UI_ADD_SPOT_LIGHT 4
#define UI_ADD_AREA_LIGHT 5
#define UI_DELETE 6
#define UI_MODE_TRANSLATE 7
#define UI_MODE_ROTATE 8
#define UI_MODE_SCALE 9
#define UI_FOCUS 10

//=============================================================================
// 数据结构
//=============================================================================

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Material {
    vec3 color;
    float shininess;
    float specularStrength;
};

struct HitResult {
    bool  hit;
    float t;
    vec3  hitPoint;
    vec3  normal;
    int   objectId;
    float targetType;
    Material material;
};

struct Transform {
    float type;
    vec3 position;
    mat3 rotation;
    vec3 scale;
    vec3 color;
};

struct Light {
    float type;
    vec3  position;
    vec3  direction;
    vec3  color;
    float intensity;
    float range;
    float angle;
    vec2  areaSize;
};

struct FrameState {
    vec3  camPos;
    vec3  camDir;
    vec2  camAngles;
    int   selectedId;
    float selectedType;
    float transformMode;
    bool  isFocusing;
    bool  showGizmos;
    int   objectCount;
    int   lightCount;
    Transform transforms[MAX_PICKABLE_COUNT];
    Light lights[MAX_LIGHT_COUNT];
};

//=============================================================================
// 矩阵函数
//=============================================================================

mat4 translate(vec3 t) {
    return mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        t.x, t. y, t.z, 1.0
    );
}

mat4 translateInv(vec3 t) {
    return translate(-t);
}

mat4 scale(vec3 s) {
    return mat4(
        s.x, 0.0, 0.0, 0.0,
        0.0, s.y, 0.0, 0.0,
        0.0, 0.0, s.z, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 scaleInv(vec3 s) {
    return scale(1.0 / s);
}

mat4 rightToLeft() {
    return scale(vec3(1.0, 1.0, -1.0));
}

mat4 rightToLeftInv() {
    return rightToLeft();
}

mat4 ortho(float l, float r, float b, float t, float n, float f) {
    return scale(vec3(2.0/(r-l), 2.0/(t-b), 2.0/(f-n))) * 
           translate(vec3(-(l+r)/2.0, -(t+b)/2.0, -(f+n)/2.0));
}

mat4 orthoInv(float l, float r, float b, float t, float n, float f) {
    return translateInv(vec3(-(l+r)/2.0, -(t+b)/2.0, -(f+n)/2.0)) *
           scaleInv(vec3(2.0/(r-l), 2.0/(t-b), 2.0/(f-n)));
}

mat4 projection(float n, float f) {
    return mat4(
        n,   0.0, 0.0,  0.0,
        0.0, n,   0.0,  0.0,
        0.0, 0.0, n+f,  1.0,
        0.0, 0.0, -f*n, 0.0
    );
}

mat4 projectionInv(float n, float f) {
    return mat4(
        1.0/n, 0.0,   0.0,        0.0,
        0.0,   1.0/n, 0.0,        0.0,
        0.0,   0.0,   0.0,       -1.0/(f*n),
        0.0,   0.0,   1.0,        (f+n)/(f*n)
    );
}

mat4 perspective(float fov, float aspect, float n, float f) {
    float l = tan(fov/2.0) * n;
    float b = l / aspect;
    return ortho(-l, l, -b, b, n, f) * projection(n, f) * rightToLeft();
}

mat4 perspectiveInv(float fov, float aspect, float n, float f) {
    float l = tan(fov/2.0) * n;
    float b = l / aspect;
    return rightToLeftInv() * projectionInv(n, f) * orthoInv(-l, l, -b, b, n, f);
}

mat4 lookAt(vec3 eye, vec3 center, vec3 up) {
    vec3 z = normalize(eye - center);
    vec3 x = normalize(cross(up, z));
    vec3 y = cross(z, x);
    return mat4(
        x. x, y.x, z.x, 0.0,
        x.y, y.y, z.y, 0.0,
        x.z, y.z, z.z, 0.0,
        0.0, 0.0, 0.0, 1.0
    ) * translate(-eye);
}

mat4 lookAtInv(vec3 eye, vec3 center, vec3 up) {
    vec3 z = normalize(eye - center);
    vec3 x = normalize(cross(up, z));
    vec3 y = cross(z, x);
    return translateInv(-eye) * mat4(
        x. x, x.y, x. z, 0.0,
        y.x, y. y, y.z, 0.0,
        z. x, z.y, z.z, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat3 rotateX3(float a) {
    float c = cos(a), s = sin(a);
    return mat3(1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c);
}

mat3 rotateY3(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c);
}

mat3 rotateZ3(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, -s, 0.0, s, c, 0.0, 0.0, 0.0, 1.0);
}

//=============================================================================
// 工具函数
//=============================================================================

vec3 anglesToDirection(vec2 a) {
    return normalize(vec3(cos(a. x) * sin(a. y), sin(a.x), cos(a.x) * cos(a.y)));
}

vec2 directionToAngles(vec3 d) {
    d = normalize(d);
    return vec2(asin(clamp(d.y, -1.0, 1.0)), atan(d.x, d.z));
}

vec3 createRayDir(vec2 uv, mat4 PInv, mat4 VInv) {
    vec4 rayEye = PInv * vec4(uv * 2.0 - 1.0, -1.0, 1.0);
    rayEye.w = 0.0;
    return normalize((VInv * rayEye).xyz);
}

vec3 rayPlaneIntersect(vec3 ro, vec3 rd, vec3 pp, vec3 pn) {
    float d = dot(rd, pn);
    if (abs(d) < 0.0001) return pp;
    return ro + rd * max(dot(pp - ro, pn) / d, 0.0);
}

float smootherStep(float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

vec3 randomColor(int seed) {
    return vec3(
        fract(sin(float(seed) * 12.9898) * 43758.5453),
        fract(sin(float(seed) * 78.233) * 43758.5453),
        fract(sin(float(seed) * 45.164) * 43758.5453)
    ) * 0.5 + 0.3;
}

//=============================================================================
// 基础光线求交
//=============================================================================

HitResult intersectSphere(vec3 ro, vec3 rd, vec3 c, float r) {
    HitResult h;
    h. hit = false;
    h.objectId = -1;
    
    vec3 oc = ro - c;
    float b = dot(oc, rd);
    float det = b * b - dot(oc, oc) + r * r;
    
    if (det < 0.0) return h;
    
    float t = -b - sqrt(det);
    if (t > 0.001) {
        h.hit = true;
        h.t = t;
        h.hitPoint = ro + rd * t;
        h. normal = normalize(h.hitPoint - c);
    }
    return h;
}

HitResult intersectBox(vec3 ro, vec3 rd, vec3 bmin, vec3 bmax) {
    HitResult h;
    h.hit = false;
    h. objectId = -1;
    
    vec3 inv = 1.0 / rd;
    vec3 t1 = (bmin - ro) * inv;
    vec3 t2 = (bmax - ro) * inv;
    vec3 tN = min(t1, t2);
    vec3 tF = max(t1, t2);
    
    float tn = max(max(tN.x, tN.y), tN.z);
    float tf = min(min(tF.x, tF.y), tF.z);
    
    if (tn > tf || tf < 0.0) return h;
    
    float t = tn > 0.0 ? tn : tf;
    if (t < 0.001) return h;
    
    h.hit = true;
    h.t = t;
    h.hitPoint = ro + rd * t;
    
    vec3 c = (bmin + bmax) * 0.5;
    vec3 p = h.hitPoint - c;
    vec3 d = abs(p) - (bmax - bmin) * 0.5;
    
    if (d.x > d.y && d. x > d.z) {
        h.normal = vec3(sign(p.x), 0.0, 0.0);
    } else if (d.y > d.z) {
        h.normal = vec3(0.0, sign(p.y), 0.0);
    } else {
        h.normal = vec3(0.0, 0.0, sign(p. z));
    }
    
    return h;
}

//=============================================================================
// 射线与线段距离
//=============================================================================

vec3 rayLineSegmentDistance(vec3 ro, vec3 rd, vec3 p0, vec3 p1) {
    vec3 u = rd;
    vec3 v = p1 - p0;
    vec3 w = ro - p0;
    
    float a = dot(u, u);
    float b = dot(u, v);
    float c = dot(v, v);
    float d = dot(u, w);
    float e = dot(v, w);
    
    float denom = a * c - b * b;
    
    float t, s;
    if (denom < 0.0001) {
        t = 0.0;
        s = e / c;
    } else {
        t = (b * e - c * d) / denom;
        s = (a * e - b * d) / denom;
    }
    
    s = clamp(s, 0.0, 1.0);
    t = max(t, 0.0);
    
    vec3 closestRay = ro + rd * t;
    vec3 closestLine = p0 + v * s;
    
    return vec3(t, s, length(closestRay - closestLine));
}

HitResult intersectLineSegment(vec3 ro, vec3 rd, vec3 p0, vec3 p1, float radius) {
    HitResult h;
    h.hit = false;
    h.objectId = -1;
    
    vec3 tsd = rayLineSegmentDistance(ro, rd, p0, p1);
    
    if (tsd.z < radius && tsd.x > 0.001) {
        h.hit = true;
        h.t = tsd.x;
        h. hitPoint = ro + rd * tsd.x;
        vec3 lineDir = normalize(p1 - p0);
        h.normal = normalize(h.hitPoint - (p0 + lineDir * tsd.y * length(p1 - p0)));
    }
    
    return h;
}

//=============================================================================
// 阴影检测
//=============================================================================

bool isInShadow(vec3 point, vec3 lightPos, Transform tr[MAX_PICKABLE_COUNT], int oc) {
    vec3 toLight = lightPos - point;
    float lightDist = length(toLight);
    vec3 lightDir = toLight / lightDist;
    
    // 稍微偏移起点，避免自相交
    vec3 ro = point + lightDir * 0.01;
    
    // 检查静态场景
    HitResult h;
    
    // 检查墙壁
    h = intersectBox(ro, lightDir, vec3(1.99, -2.0, -2.0), vec3(2.01, 2.0, 2.0));
    if (h.hit && h.t < lightDist) return true;
    
    h = intersectBox(ro, lightDir, vec3(-2.0, -2.0, 1.99), vec3(2.0, 2.0, 2.01));
    if (h.hit && h.t < lightDist) return true;
    
    h = intersectBox(ro, lightDir, vec3(-2.01, -2.0, -2.0), vec3(-1.99, 2.0, 2.0));
    if (h.hit && h.t < lightDist) return true;
    
    h = intersectBox(ro, lightDir, vec3(-2.0, -2.01, -2.0), vec3(2.0, -1.99, 2.0));
    if (h.hit && h.t < lightDist) return true;
    
    // 检查动态物体
    for (int i = 0; i < MAX_PICKABLE_COUNT; i++) {
        if (i >= oc) break;
        if (tr[i]. type < 0.0) continue;
        
        if (tr[i]. type == OBJ_TYPE_SPHERE) {
            float s = (tr[i].scale.x + tr[i].scale.y + tr[i]. scale.z) / 3.0;
            h = intersectSphere(ro, lightDir, tr[i].position, 0.5 * s);
        } else {
            mat3 invR = transpose(tr[i].rotation);
            vec3 lo = invR * (ro - tr[i]. position);
            vec3 ld = normalize(invR * lightDir);
            h = intersectBox(lo, ld, -tr[i].scale * 0.5, tr[i].scale * 0.5);
        }
        
        if (h.hit && h.t < lightDist) return true;
    }
    
    return false;
}

//=============================================================================
// 光照计算
//=============================================================================

vec3 calcPointLight(Light l, vec3 p, vec3 n, vec3 v, Material m) {
    vec3 toL = l.position - p;
    float d = length(toL);
    vec3 lDir = toL / d;
    
    float att = 1.0 / (1.0 + d * d / (l.range * l.range));
    float diff = max(dot(n, lDir), 0.0);
    
    vec3 halfDir = normalize(lDir + v);
    float spec = pow(max(dot(n, halfDir), 0.0), m.shininess);
    
    return (diff * m.color + spec * m.specularStrength) * l.color * l.intensity * att;
}

vec3 calcSpotLight(Light l, vec3 p, vec3 n, vec3 v, Material m) {
    vec3 toL = l. position - p;
    float d = length(toL);
    vec3 lDir = toL / d;
    
    float theta = dot(lDir, -l.direction);
    float cutoff = cos(l.angle);
    float outer = cos(l.angle * 1.3);
    float spot = clamp((theta - outer) / (cutoff - outer), 0.0, 1.0);
    
    if (spot <= 0.0) return vec3(0.0);
    
    float att = 1.0 / (1.0 + d * d / (l.range * l. range));
    float diff = max(dot(n, lDir), 0.0);
    
    vec3 halfDir = normalize(lDir + v);
    float spec = pow(max(dot(n, halfDir), 0.0), m.shininess);
    
    return (diff * m.color + spec * m. specularStrength) * l.color * l.intensity * att * spot;
}

vec3 calcAreaLight(Light l, vec3 p, vec3 n, vec3 v, Material m,
                   Transform tr[MAX_PICKABLE_COUNT], int oc) {
    vec3 right = normalize(cross(l.direction, vec3(0.0, 1.0, 0.001)));
    vec3 up = cross(right, l.direction);
    
    vec3 total = vec3(0.0);
    float samples = 0.0;
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec3 sp = l.position + right * float(i) * l.areaSize.x * 0.5 
                                 + up * float(j) * l.areaSize.y * 0.5;
            
            // 阴影检测
            if (isInShadow(p, sp, tr, oc)) continue;
            
            vec3 toL = sp - p;
            float d = length(toL);
            vec3 lDir = toL / d;
            
            float facing = max(dot(-lDir, l.direction), 0.0);
            if (facing <= 0.0) continue;
            
            float att = 1.0 / (1.0 + d * d / (l.range * l.range));
            float diff = max(dot(n, lDir), 0.0);
            
            vec3 halfDir = normalize(lDir + v);
            float spec = pow(max(dot(n, halfDir), 0.0), m.shininess);
            
            total += (diff * m.color + spec * m.specularStrength) * att * facing;
            samples += 1.0;
        }
    }
    
    return total * l.color * l.intensity / max(samples, 1.0);
}

vec3 calculateLighting(vec3 p, vec3 n, vec3 vp, Material m, 
                       Light lights[MAX_LIGHT_COUNT], int lc,
                       Transform tr[MAX_PICKABLE_COUNT], int oc) {
    vec3 col = ambientColor * m.color;
    vec3 v = normalize(vp - p);
    
    for (int i = 0; i < MAX_LIGHT_COUNT; i++) {
        if (i >= lc) break;
        Light l = lights[i];
        if (l.type < 0.0) continue;
        
        // 阴影检测
        vec3 lightPos = l.position;
        if (isInShadow(p, lightPos, tr, oc)) continue;
        
        if (l.type == LIGHT_TYPE_POINT) {
            col += calcPointLight(l, p, n, v, m);
        } else if (l.type == LIGHT_TYPE_SPOT) {
            col += calcSpotLight(l, p, n, v, m);
        } else if (l. type == LIGHT_TYPE_AREA) {
            col += calcAreaLight(l, p, n, v, m, tr, oc);
        }
    }
    
    return col;
}

//=============================================================================
// 物体求交
//=============================================================================

HitResult createSphere(Ray ray, vec3 c, float r, vec3 col, int id) {
    HitResult h = intersectSphere(ray.origin, ray.direction, c, r);
    if (h.hit) {
        h. objectId = id;
        h.targetType = TARGET_OBJECT;
        h. material. color = col;
        h.material. shininess = 32.0;
        h.material.specularStrength = 0.5;
    }
    return h;
}

HitResult createBox(Ray ray, vec3 c, vec3 s, vec3 col, int id) {
    HitResult h = intersectBox(ray.origin, ray.direction, c - s, c + s);
    if (h.hit) {
        h.objectId = id;
        h.targetType = TARGET_OBJECT;
        h.material.color = col;
        h.material.shininess = 16.0;
        h.material.specularStrength = 0.3;
    }
    return h;
}

HitResult createTransformedBox(Ray ray, vec3 c, vec3 s, mat3 rot, vec3 col, int id) {
    mat3 invR = transpose(rot);
    vec3 lo = invR * (ray.origin - c);
    vec3 ld = normalize(invR * ray.direction);
    
    HitResult h = intersectBox(lo, ld, -s, s);
    if (h. hit) {
        h.normal = normalize(rot * h.normal);
        h.hitPoint = ray.origin + ray.direction * h.t;
        h.objectId = id;
        h.targetType = TARGET_OBJECT;
        h.material.color = col;
        h.material.shininess = 16.0;
        h.material. specularStrength = 0.3;
    }
    return h;
}

//=============================================================================
// 光源线框拾取（使用 PICK_* 参数）
//=============================================================================

HitResult pickPointLightWireframe(Ray ray, Light light, int id) {
    HitResult best;
    best.hit = false;
    best.t = INF;
    best.objectId = -1;
    
    vec3 c = light.position;
    float r = PICK_BULB_RADIUS;
    float bh = r * 0.8;
    float br = r * 0.5;
    int seg = 12;
    
    for (int i = 0; i < seg; i++) {
        float a0 = float(i) / float(seg) * TAU;
        float a1 = float(i + 1) / float(seg) * TAU;
        vec3 p0 = c + vec3(cos(a0), 0.0, sin(a0)) * r;
        vec3 p1 = c + vec3(cos(a1), 0.0, sin(a1)) * r;
        HitResult h = intersectLineSegment(ray. origin, ray.direction, p0, p1, PICK_LINE_RADIUS);
        if (h.hit && h.t < best.t) best = h;
    }
    
    for (int i = 0; i < seg; i++) {
        float a0 = float(i) / float(seg) * TAU;
        float a1 = float(i + 1) / float(seg) * TAU;
        vec3 p0 = c + vec3(cos(a0), sin(a0), 0.0) * r;
        vec3 p1 = c + vec3(cos(a1), sin(a1), 0.0) * r;
        HitResult h = intersectLineSegment(ray.origin, ray.direction, p0, p1, PICK_LINE_RADIUS);
        if (h.hit && h.t < best.t) best = h;
    }
    
    for (int i = 0; i < seg; i++) {
        float a0 = float(i) / float(seg) * TAU;
        float a1 = float(i + 1) / float(seg) * TAU;
        vec3 p0 = c + vec3(0.0, sin(a0), cos(a0)) * r;
        vec3 p1 = c + vec3(0.0, sin(a1), cos(a1)) * r;
        HitResult h = intersectLineSegment(ray.origin, ray.direction, p0, p1, PICK_LINE_RADIUS);
        if (h.hit && h.t < best.t) best = h;
    }
    
    vec3 bb = c - vec3(0.0, r, 0.0);
    vec3 bbot = bb - vec3(0.0, bh, 0.0);
    
    for (int i = 0; i < 4; i++) {
        float a = float(i) / 4.0 * TAU;
        vec3 off = vec3(cos(a), 0.0, sin(a));
        vec3 top = bb + off * br * 0.6;
        vec3 bot = bbot + off * br;
        HitResult h = intersectLineSegment(ray. origin, ray.direction, top, bot, PICK_LINE_RADIUS);
        if (h.hit && h.t < best.t) best = h;
    }
    
    for (int i = 0; i < seg; i++) {
        float a0 = float(i) / float(seg) * TAU;
        float a1 = float(i + 1) / float(seg) * TAU;
        vec3 p0 = bbot + vec3(cos(a0), 0.0, sin(a0)) * br;
        vec3 p1 = bbot + vec3(cos(a1), 0.0, sin(a1)) * br;
        HitResult h = intersectLineSegment(ray. origin, ray.direction, p0, p1, PICK_LINE_RADIUS);
        if (h.hit && h. t < best.t) best = h;
    }
    
    if (best.hit) {
        best.objectId = id;
        best. targetType = TARGET_LIGHT;
        best. material.color = light.color;
        best.material.shininess = 1.0;
        best.material.specularStrength = 0.0;
    }
    
    return best;
}

HitResult pickSpotLightWireframe(Ray ray, Light light, int id) {
    HitResult best;
    best. hit = false;
    best.t = INF;
    best.objectId = -1;
    
    vec3 apex = light.position;
    vec3 axis = normalize(light. direction);
    float h = PICK_CONE_HEIGHT;
    float r = h * tan(light.angle * 0.8);
    
    vec3 up = abs(axis.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 right = normalize(cross(up, axis));
    up = cross(axis, right);
    vec3 bc = apex + axis * h;
    
    int seg = 12;
    
    for (int i = 0; i < seg; i++) {
        float a0 = float(i) / float(seg) * TAU;
        float a1 = float(i + 1) / float(seg) * TAU;
        vec3 p0 = bc + (right * cos(a0) + up * sin(a0)) * r;
        vec3 p1 = bc + (right * cos(a1) + up * sin(a1)) * r;
        HitResult hit = intersectLineSegment(ray.origin, ray.direction, p0, p1, PICK_LINE_RADIUS);
        if (hit. hit && hit.t < best.t) best = hit;
    }
    
    for (int i = 0; i < 4; i++) {
        float a = float(i) / 4.0 * TAU;
        vec3 bp = bc + (right * cos(a) + up * sin(a)) * r;
        HitResult hit = intersectLineSegment(ray.origin, ray.direction, apex, bp, PICK_LINE_RADIUS);
        if (hit.hit && hit.t < best. t) best = hit;
    }
    
    if (best.hit) {
        best. objectId = id;
        best.targetType = TARGET_LIGHT;
        best.material.color = light.color;
        best.material. shininess = 1.0;
        best.material.specularStrength = 0.0;
    }
    
    return best;
}

HitResult pickAreaLightWireframe(Ray ray, Light light, int id) {
    HitResult best;
    best.hit = false;
    best.t = INF;
    best.objectId = -1;
    
    vec3 c = light.position;
    vec3 n = normalize(light. direction);
    vec3 up = abs(n. y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 right = normalize(cross(up, n));
    up = cross(n, right);
    vec2 size = light.areaSize * PICK_AREA_SCALE;
    
    vec3 corners[4];
    corners[0] = c + right * size. x * 0.5 + up * size. y * 0.5;
    corners[1] = c - right * size.x * 0.5 + up * size.y * 0.5;
    corners[2] = c - right * size.x * 0.5 - up * size.y * 0.5;
    corners[3] = c + right * size.x * 0.5 - up * size. y * 0.5;
    
    for (int i = 0; i < 4; i++) {
        int next = (i + 1) % 4;
        HitResult h = intersectLineSegment(ray. origin, ray.direction, corners[i], corners[next], PICK_LINE_RADIUS);
        if (h.hit && h.t < best.t) best = h;
    }
    
    for (int i = 0; i < 4; i++) {
        HitResult h = intersectLineSegment(ray.origin, ray.direction, c, corners[i], PICK_LINE_RADIUS);
        if (h.hit && h.t < best.t) best = h;
    }
    
    if (best.hit) {
        best.objectId = id;
        best. targetType = TARGET_LIGHT;
        best.material.color = light.color;
        best.material.shininess = 1.0;
        best.material. specularStrength = 0.0;
    }
    
    return best;
}

HitResult createLightGizmo(Ray ray, Light light, int id) {
    HitResult h;
    h. hit = false;
    h.objectId = -1;
    
    if (light.type < 0.0) return h;
    
    if (light. type == LIGHT_TYPE_POINT) {
        return pickPointLightWireframe(ray, light, id);
    } else if (light.type == LIGHT_TYPE_SPOT) {
        return pickSpotLightWireframe(ray, light, id);
    } else if (light.type == LIGHT_TYPE_AREA) {
        return pickAreaLightWireframe(ray, light, id);
    }
    
    return h;
}

//=============================================================================
// 场景求交
//=============================================================================

HitResult traceStaticScene(Ray ray) {
    HitResult cl;
    cl.hit = false;
    cl.t = INF;
    cl.objectId = -1;
    
    HitResult h[4];
    h[0] = createBox(ray, vec3(2, 0, 0), vec3(0.01, 2, 2), vec3(1, 0, 0), -1);
    h[1] = createBox(ray, vec3(0, 0, 2), vec3(2, 2, 0.01), vec3(1), -1);
    h[2] = createBox(ray, vec3(-2, 0, 0), vec3(0.01, 2, 2), vec3(0, 1, 0), -1);
    h[3] = createBox(ray, vec3(0, -2, 0), vec3(2, 0.01, 2), vec3(1), -1);
    
    for (int i = 0; i < 4; i++) {
        if (h[i]. hit && h[i].t < cl.t) cl = h[i];
    }
    return cl;
}

HitResult tracePickableObjects(Ray ray, Transform tr[MAX_PICKABLE_COUNT], int oc) {
    HitResult cl;
    cl.hit = false;
    cl.t = INF;
    cl. objectId = -1;
    
    for (int i = 0; i < MAX_PICKABLE_COUNT; i++) {
        if (i >= oc) break;
        if (tr[i]. type < 0.0) continue;
        
        HitResult h;
        if (tr[i]. type == OBJ_TYPE_SPHERE) {
            float s = (tr[i].scale.x + tr[i].scale.y + tr[i]. scale.z) / 3.0;
            h = createSphere(ray, tr[i].position, 0.5 * s, tr[i].color, i);
        } else {
            h = createTransformedBox(ray, tr[i]. position, tr[i].scale * 0.5, tr[i].rotation, tr[i]. color, i);
        }
        
        if (h. hit && h.t < cl.t) cl = h;
    }
    return cl;
}

HitResult traceLights(Ray ray, Light lt[MAX_LIGHT_COUNT], int lc) {
    HitResult cl;
    cl.hit = false;
    cl. t = INF;
    cl.objectId = -1;
    
    for (int i = 0; i < MAX_LIGHT_COUNT; i++) {
        if (i >= lc) break;
        HitResult h = createLightGizmo(ray, lt[i], i);
        if (h.hit && h. t < cl.t) cl = h;
    }
    return cl;
}

HitResult traceScene(Ray ray, Transform tr[MAX_PICKABLE_COUNT], int oc, Light lt[MAX_LIGHT_COUNT], int lc) {
    HitResult s = traceStaticScene(ray);
    HitResult o = tracePickableObjects(ray, tr, oc);
    
    HitResult cl = s;
    if (o.hit && o.t < cl.t) cl = o;
    
    #ifdef DEBUG_SHOW_PICK_GEOMETRY
    HitResult l = traceLights(ray, lt, lc);
    if (l.hit && l.t < cl.t) cl = l;
    #endif
    
    return cl;
}

HitResult pickScene(Ray ray, Transform tr[MAX_PICKABLE_COUNT], int oc, Light lt[MAX_LIGHT_COUNT], int lc) {
    HitResult o = tracePickableObjects(ray, tr, oc);
    HitResult l = traceLights(ray, lt, lc);
    
    if (l.hit && l. t < o.t) {
        return l;
    }
    return o;
}

//=============================================================================
// 状态读取
//=============================================================================

#ifndef IS_BUFFER_A

vec4 loadState(sampler2D buf, ivec2 p) {
    return texelFetch(buf, p, 0);
}

FrameState loadFrameState(sampler2D buf) {
    FrameState st;
    
    st.camDir = loadState(buf, ivec2(2, ROW_MOUSE)).xyz;
    st. camPos = loadState(buf, ivec2(3, ROW_MOUSE)).xyz;
    st.camAngles = loadState(buf, ivec2(1, ROW_MOUSE)).xy;
    
    vec4 ps = loadState(buf, ivec2(0, ROW_SELECT));
    st.selectedId = int(ps.x);
    st.selectedType = ps.y;
    st.transformMode = ps.w;
    
    vec4 focusData = loadState(buf, ivec2(1, ROW_KEYS));
    st.isFocusing = focusData. x > 0.5;
    st. showGizmos = focusData.z > 0.5;
    
    vec4 cnt = loadState(buf, ivec2(1, ROW_COUNTS));
    st.objectCount = int(cnt.x);
    st.lightCount = int(cnt. y);
    
    for (int i = 0; i < MAX_PICKABLE_COUNT; i++) {
        vec4 tp = loadState(buf, ivec2(i, ROW_OBJ_POS));
        st.transforms[i]. type = tp.w;
        st. transforms[i].position = tp.xyz;
        st. transforms[i].scale = loadState(buf, ivec2(i, ROW_OBJ_SCALE)).xyz;
        st.transforms[i]. color = loadState(buf, ivec2(i, ROW_OBJ_COLOR)).xyz;
        st.transforms[i].rotation = mat3(
            loadState(buf, ivec2(i, ROW_OBJ_ROT0)).xyz,
            loadState(buf, ivec2(i, ROW_OBJ_ROT1)).xyz,
            loadState(buf, ivec2(i, ROW_OBJ_ROT2)).xyz
        );
    }
    
    for (int i = 0; i < MAX_LIGHT_COUNT; i++) {
        vec4 pt = loadState(buf, ivec2(i, ROW_LIGHT_POS));
        st.lights[i].type = pt.w;
        st.lights[i].position = pt.xyz;
        
        vec4 da = loadState(buf, ivec2(i, ROW_LIGHT_DIR));
        st.lights[i].direction = da.xyz;
        st.lights[i]. angle = da.w;
        
        vec4 ci = loadState(buf, ivec2(i, ROW_LIGHT_COL));
        st.lights[i]. color = ci.xyz;
        st. lights[i].intensity = ci.w;
        
        vec4 pm = loadState(buf, ivec2(i, ROW_LIGHT_PRM));
        st.lights[i].range = pm.x;
        st.lights[i].areaSize = pm. yz;
    }
    
    return st;
}

#endif

//=============================================================================
// UI
//=============================================================================

float uiRoundedBox(vec2 p, vec2 s, float r) {
    vec2 d = abs(p) - s + r;
    return min(max(d. x, d.y), 0.0) + length(max(d, vec2(0.0))) - r;
}

float uiIconTranslate(vec2 p) {
    float d = min(max(abs(p.x) - 0.1, abs(p.y) - 0.6), max(abs(p. y) - 0.1, abs(p. x) - 0.6));
    vec2 ap = abs(p);
    if (ap.x > 0.4 || ap.y > 0.4) {
        d = min(d, max(ap.x + ap.y - 0.85, 0.15 - min(ap.x, ap.y)));
    }
    return d;
}

float uiIconRotate(vec2 p) {
    float r = length(p);
    float a = atan(p.y, p.x);
    float arc = abs(r - 0.4) - 0.1;
    if (a > 2.0 || a < -1.0) arc = 1.0;
    vec2 ap = p - vec2(0.0, 0.45);
    return min(arc, max(abs(ap.x + ap.y * 0.5), abs(ap.y - ap.x * 0.5)) - 0.18);
}

float uiIconScale(vec2 p) {
    float diag = max(abs(p. x - p.y) - 0.12, max(abs(p. x) - 0.55, abs(p. y) - 0.55));
    return min(diag, min(max(abs(p.x + 0.4), abs(p.y + 0.4)) - 0.18, 
                         max(abs(p.x - 0.4), abs(p.y - 0.4)) - 0.18));
}

float uiIconFocus(vec2 p) {
    float d = max(abs(p. x + 0.25) - 0.12, abs(p.y) - 0.55);
    d = min(d, max(abs(p. x + 0.05) - 0.35, abs(p. y - 0.42) - 0.12));
    return min(d, max(abs(p. x + 0.1) - 0.25, abs(p. y + 0.05) - 0.1));
}

float uiIconSphere(vec2 p) {
    return length(p) - 0.4;
}

float uiIconBox(vec2 p) {
    vec2 d = abs(p) - vec2(0.35);
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2(0.0)));
}

float uiIconDelete(vec2 p) {
    return max(min(abs(p. x - p.y) - 0.12, abs(p.x + p.y) - 0.12), max(abs(p. x), abs(p.y)) - 0.5);
}

float uiIconPointLight(vec2 p) {
    float sun = length(p) - 0.25;
    float rays = INF;
    for (int i = 0; i < 8; i++) {
        float a = float(i) * TAU / 8.0;
        rays = min(rays, length(p - vec2(cos(a), sin(a)) * 0.4) - 0.05);
    }
    return min(sun, rays);
}

float uiIconSpotLight(vec2 p) {
    float cone = max(abs(p.x) - (0.4 - p.y * 0.35), -p.y - 0.25);
    cone = max(cone, p.y - 0.45);
    return min(cone, length(p - vec2(0.0, 0.5)) - 0.12);
}

float uiIconAreaLight(vec2 p) {
    vec2 d = abs(p) - vec2(0.4, 0.25);
    float rect = min(max(d.x, d.y), 0.0) + length(max(d, vec2(0.0))) - 0.02;
    float arrow = max(abs(p. x) - 0.04, abs(p. y + 0.15) - 0.2);
    arrow = min(arrow, max(abs(p.x) - 0.1, p.y + 0.3));
    return min(rect, arrow);
}

int checkUIClick(vec2 fc, int selId, float selType, vec2 res) {
    float btnS = 36.0, gap = 6.0, margin = 12.0;
    float rx = res.x - margin - btnS;
    int idx = 0;
    vec2 c;
    
    c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx) * (btnS + gap));
    if (uiRoundedBox(fc - c, vec2(btnS * 0.5 - 2.0), 5.0) < 0.0) return UI_ADD_SPHERE;
    idx++;
    
    c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx) * (btnS + gap));
    if (uiRoundedBox(fc - c, vec2(btnS * 0.5 - 2.0), 5.0) < 0.0) return UI_ADD_BOX;
    idx++;
    
    c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx) * (btnS + gap));
    if (uiRoundedBox(fc - c, vec2(btnS * 0.5 - 2.0), 5.0) < 0.0) return UI_ADD_POINT_LIGHT;
    idx++;
    
    c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx) * (btnS + gap));
    if (uiRoundedBox(fc - c, vec2(btnS * 0.5 - 2.0), 5.0) < 0.0) return UI_ADD_SPOT_LIGHT;
    idx++;
    
    c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx) * (btnS + gap));
    if (uiRoundedBox(fc - c, vec2(btnS * 0.5 - 2.0), 5.0) < 0.0) return UI_ADD_AREA_LIGHT;
    idx++;
    
    if (selId >= 0) {
        c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx) * (btnS + gap));
        if (uiRoundedBox(fc - c, vec2(btnS * 0.5 - 2.0), 5.0) < 0.0) return UI_DELETE;
    }
    
    if (selId >= 0) {
        idx = 0;
        
        c = vec2(margin + btnS * 0.5 + float(idx) * (btnS + gap), margin + btnS * 0.5);
        if (uiRoundedBox(fc - c, vec2(btnS * 0.5 - 2.0), 5.0) < 0.0) return UI_MODE_TRANSLATE;
        idx++;
        
        c = vec2(margin + btnS * 0.5 + float(idx) * (btnS + gap), margin + btnS * 0.5);
        if (uiRoundedBox(fc - c, vec2(btnS * 0.5 - 2.0), 5.0) < 0.0) return UI_MODE_ROTATE;
        idx++;
        
        c = vec2(margin + btnS * 0.5 + float(idx) * (btnS + gap), margin + btnS * 0.5);
        if (uiRoundedBox(fc - c, vec2(btnS * 0.5 - 2.0), 5.0) < 0.0) return UI_MODE_SCALE;
        idx++;
        
        c = vec2(margin + btnS * 0.5 + float(idx) * (btnS + gap) + gap * 2.0, margin + btnS * 0.5);
        if (uiRoundedBox(fc - c, vec2(btnS * 0.5 - 2.0), 5.0) < 0.0) return UI_FOCUS;
    }
    
    return UI_NONE;
}

vec3 renderUI(vec2 fc, FrameState st, float time, vec2 res, vec3 base) {
    float btnS = 36.0, gap = 6.0, margin = 12.0;
    float rx = res.x - margin - btnS;
    bool sel = st.selectedId >= 0;
    float tm = st.transformMode;
    
    vec3 cSph = vec3(0.9, 0.4, 0.7);
    vec3 cBox = vec3(0.4, 0.8, 0.9);
    vec3 cPt = vec3(1.0, 0.9, 0.4);
    vec3 cSpt = vec3(0.9, 0.7, 0.3);
    vec3 cAr = vec3(0.7, 0.9, 0.5);
    vec3 cDel = vec3(0.9, 0.3, 0.3);
    vec3 cTr = vec3(0.3, 0.8, 0.4);
    vec3 cRot = vec3(0.3, 0.5, 0.9);
    vec3 cScl = vec3(0.9, 0.5, 0.2);
    vec3 cFoc = vec3(0.8, 0.8, 0.3);
    
    int idx = 0;
    vec2 c;
    vec2 p;
    float d, ico;
    
    c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx++) * (btnS + gap));
    p = fc - c; d = uiRoundedBox(p, vec2(btnS * 0.5 - 2.0), 5.0);
    if (d < 0.0) { ico = uiIconSphere(p / (btnS * 0.32));
        base = mix(base, cSph, 0.4); if (ico < 0.0) base = cSph; if (d > -2.0) base = cSph * 0.6; }
    
    c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx++) * (btnS + gap));
    p = fc - c; d = uiRoundedBox(p, vec2(btnS * 0.5 - 2.0), 5.0);
    if (d < 0.0) { ico = uiIconBox(p / (btnS * 0.32));
        base = mix(base, cBox, 0.4); if (ico < 0.0) base = cBox; if (d > -2.0) base = cBox * 0.6; }
    
    c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx++) * (btnS + gap));
    p = fc - c; d = uiRoundedBox(p, vec2(btnS * 0.5 - 2.0), 5.0);
    if (d < 0.0) { ico = uiIconPointLight(p / (btnS * 0.32));
        base = mix(base, cPt, 0.4); if (ico < 0.0) base = cPt; if (d > -2.0) base = cPt * 0.6; }
    
    c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx++) * (btnS + gap));
    p = fc - c; d = uiRoundedBox(p, vec2(btnS * 0.5 - 2.0), 5.0);
    if (d < 0.0) { ico = uiIconSpotLight(p / (btnS * 0.32));
        base = mix(base, cSpt, 0.4); if (ico < 0.0) base = cSpt; if (d > -2.0) base = cSpt * 0.6; }
    
    c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx++) * (btnS + gap));
    p = fc - c; d = uiRoundedBox(p, vec2(btnS * 0.5 - 2.0), 5.0);
    if (d < 0.0) { ico = uiIconAreaLight(p / (btnS * 0.32));
        base = mix(base, cAr, 0.4); if (ico < 0.0) base = cAr; if (d > -2.0) base = cAr * 0.6; }
    
    if (sel) {
        c = vec2(rx + btnS * 0.5, margin + btnS * 0.5 + float(idx) * (btnS + gap));
        p = fc - c; d = uiRoundedBox(p, vec2(btnS * 0.5 - 2.0), 5.0);
        if (d < 0.0) { ico = uiIconDelete(p / (btnS * 0.32));
            base = mix(base, cDel, 0.4); if (ico < 0.0) base = cDel; if (d > -2.0) base = cDel * 0.6; }
    }
    
    if (sel) {
        idx = 0;
        
        c = vec2(margin + btnS * 0.5 + float(idx++) * (btnS + gap), margin + btnS * 0.5);
        p = fc - c; d = uiRoundedBox(p, vec2(btnS * 0.5 - 2.0), 5.0);
        if (d < 0.0) { ico = uiIconTranslate(p / (btnS * 0.32)); bool act = (tm == TRANSFORM_TRANSLATE);
            if (act) { base = cTr; if (ico < 0.0) base = vec3(1.0); }
            else { base = mix(base, cTr, 0.4); if (ico < 0.0) base = cTr; }
            if (d > -2.0) base = cTr * 0.6; }
        
        c = vec2(margin + btnS * 0.5 + float(idx++) * (btnS + gap), margin + btnS * 0.5);
        p = fc - c; d = uiRoundedBox(p, vec2(btnS * 0.5 - 2.0), 5.0);
        if (d < 0.0) { ico = uiIconRotate(p / (btnS * 0.32)); bool act = (tm == TRANSFORM_ROTATE);
            if (act) { base = cRot; if (ico < 0.0) base = vec3(1.0); }
            else { base = mix(base, cRot, 0.4); if (ico < 0.0) base = cRot; }
            if (d > -2.0) base = cRot * 0.6; }
        
        c = vec2(margin + btnS * 0.5 + float(idx++) * (btnS + gap), margin + btnS * 0.5);
        p = fc - c; d = uiRoundedBox(p, vec2(btnS * 0.5 - 2.0), 5.0);
        if (d < 0.0) { ico = uiIconScale(p / (btnS * 0.32)); bool act = (tm == TRANSFORM_SCALE);
            if (act) { base = cScl; if (ico < 0.0) base = vec3(1.0); }
            else { base = mix(base, cScl, 0.4); if (ico < 0.0) base = cScl; }
            if (d > -2.0) base = cScl * 0.6; }
        
        c = vec2(margin + btnS * 0.5 + float(idx) * (btnS + gap) + gap * 2.0, margin + btnS * 0.5);
        p = fc - c; d = uiRoundedBox(p, vec2(btnS * 0.5 - 2.0), 5.0);
        if (d < 0.0) { ico = uiIconFocus(p / (btnS * 0.32));
            if (st.isFocusing) { float pu = 0.5 + 0.5 * sin(time * 8.0); base = mix(cFoc, vec3(1.0), pu * 0.3); }
            else { base = mix(base, cFoc, 0.4); if (ico < 0.0) base = cFoc; }
            if (d > -2.0) base = cFoc * 0.6; }
    }
    
    return base;
}

//=============================================================================
// 光源线框渲染（使用 VISUAL_* 参数）
//=============================================================================

vec4 renderLine2D(vec2 fc, vec3 p0, vec3 p1, vec3 col, float w, mat4 vp, vec2 res) {
    vec4 c0 = vp * vec4(p0, 1.0);
    vec4 c1 = vp * vec4(p1, 1.0);
    
    if (c0.w < 0.1 || c1.w < 0.1) return vec4(0.0);
    
    vec2 s0 = (c0.xy / c0.w * 0.5 + 0.5) * res;
    vec2 s1 = (c1.xy / c1.w * 0.5 + 0.5) * res;
    
    vec2 d = s1 - s0;
    float len = length(d);
    if (len < 0.001) return vec4(0.0);
    d /= len;
    
    vec2 tf = fc - s0;
    float along = dot(tf, d);
    float perp = abs(dot(tf, vec2(-d.y, d.x)));
    
    if (along >= 0.0 && along <= len && perp < w) {
        // 边缘抗锯齿，但保持高不透明度
        float alpha = smoothstep(w, w * 0.5, perp);
        return vec4(col, alpha);
    }
    return vec4(0.0);
}

vec3 renderLightGizmos(vec2 fc, FrameState st, mat4 vp, vec2 res, vec3 base) {
    if (!st.showGizmos) return base;
    
    for (int i = 0; i < MAX_LIGHT_COUNT; i++) {
        if (i >= st.lightCount) break;
        Light l = st.lights[i];
        if (l.type < 0.0) continue;
        
        bool sel = (st.selectedType == TARGET_LIGHT && i == st. selectedId);
        vec3 col = sel ? GIZMO_COLOR_SELECTED : GIZMO_COLOR;
        float lw = sel ? LINE_WIDTH_SELECTED : LINE_WIDTH;
        
        vec4 lc = vec4(0.0);
        
        if (l. type == LIGHT_TYPE_POINT) {
            vec3 c = l.position;
            float r = VISUAL_BULB_RADIUS;
            float bh = r * 0.8;
            float br = r * 0.5;
            int seg = 24;
            
            for (int j = 0; j < seg; j++) {
                float a0 = float(j) / float(seg) * TAU;
                float a1 = float(j + 1) / float(seg) * TAU;
                vec3 p0 = c + vec3(cos(a0), 0.0, sin(a0)) * r;
                vec3 p1 = c + vec3(cos(a1), 0.0, sin(a1)) * r;
                vec4 ln = renderLine2D(fc, p0, p1, col, lw, vp, res);
                if (ln.a > lc.a) lc = ln;
            }
            
            for (int j = 0; j < seg; j++) {
                float a0 = float(j) / float(seg) * TAU;
                float a1 = float(j + 1) / float(seg) * TAU;
                vec3 p0 = c + vec3(cos(a0), sin(a0), 0.0) * r;
                vec3 p1 = c + vec3(cos(a1), sin(a1), 0.0) * r;
                vec4 ln = renderLine2D(fc, p0, p1, col, lw, vp, res);
                if (ln.a > lc.a) lc = ln;
            }
            
            for (int j = 0; j < seg; j++) {
                float a0 = float(j) / float(seg) * TAU;
                float a1 = float(j + 1) / float(seg) * TAU;
                vec3 p0 = c + vec3(0.0, sin(a0), cos(a0)) * r;
                vec3 p1 = c + vec3(0.0, sin(a1), cos(a1)) * r;
                vec4 ln = renderLine2D(fc, p0, p1, col, lw, vp, res);
                if (ln.a > lc.a) lc = ln;
            }
            
            vec3 bb = c - vec3(0.0, r, 0.0);
            vec3 bbot = bb - vec3(0.0, bh, 0.0);
            
            for (int j = 0; j < 4; j++) {
                float a = float(j) / 4.0 * TAU;
                vec3 off = vec3(cos(a), 0.0, sin(a));
                vec3 top = bb + off * br * 0.6;
                vec3 bot = bbot + off * br;
                vec4 ln = renderLine2D(fc, top, bot, col, lw, vp, res);
                if (ln. a > lc. a) lc = ln;
            }
            
            for (int j = 0; j < seg; j++) {
                float a0 = float(j) / float(seg) * TAU;
                float a1 = float(j + 1) / float(seg) * TAU;
                vec3 p0 = bbot + vec3(cos(a0), 0.0, sin(a0)) * br;
                vec3 p1 = bbot + vec3(cos(a1), 0.0, sin(a1)) * br;
                vec4 ln = renderLine2D(fc, p0, p1, col, lw, vp, res);
                if (ln.a > lc.a) lc = ln;
            }
        }
        else if (l.type == LIGHT_TYPE_SPOT) {
            vec3 apex = l.position;
            vec3 axis = normalize(l. direction);
            float h = VISUAL_CONE_HEIGHT;
            float r = h * tan(l.angle * 0.8);
            
            vec3 up = abs(axis.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
            vec3 right = normalize(cross(up, axis));
            up = cross(axis, right);
            vec3 bc = apex + axis * h;
            
            int seg = 24;
            
            for (int j = 0; j < seg; j++) {
                float a0 = float(j) / float(seg) * TAU;
                float a1 = float(j + 1) / float(seg) * TAU;
                vec3 p0 = bc + (right * cos(a0) + up * sin(a0)) * r;
                vec3 p1 = bc + (right * cos(a1) + up * sin(a1)) * r;
                vec4 ln = renderLine2D(fc, p0, p1, col, lw, vp, res);
                if (ln.a > lc.a) lc = ln;
            }
            
            for (int j = 0; j < 4; j++) {
                float a = float(j) / 4.0 * TAU;
                vec3 bp = bc + (right * cos(a) + up * sin(a)) * r;
                vec4 ln = renderLine2D(fc, apex, bp, col, lw, vp, res);
                if (ln.a > lc.a) lc = ln;
            }
        }
        else if (l.type == LIGHT_TYPE_AREA) {
            vec3 c = l.position;
            vec3 n = normalize(l. direction);
            vec3 up = abs(n. y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
            vec3 right = normalize(cross(up, n));
            up = cross(n, right);
            vec2 size = l.areaSize * VISUAL_AREA_SCALE;
            
            vec3 corners[4];
            corners[0] = c + right * size.x * 0.5 + up * size.y * 0.5;
            corners[1] = c - right * size.x * 0.5 + up * size.y * 0.5;
            corners[2] = c - right * size.x * 0.5 - up * size.y * 0.5;
            corners[3] = c + right * size.x * 0.5 - up * size. y * 0.5;
            
            for (int j = 0; j < 4; j++) {
                int next = (j + 1) % 4;
                vec4 ln = renderLine2D(fc, corners[j], corners[next], col, lw, vp, res);
                if (ln.a > lc.a) lc = ln;
            }
            
            for (int j = 0; j < 4; j++) {
                vec4 ln = renderLine2D(fc, c, corners[j], col, lw, vp, res);
                if (ln.a > lc.a) lc = ln;
            }
        }
        
        if (lc.a > 0.0) {
            // 直接覆盖，不做混合，保持线框颜色纯净
            base = mix(base, lc.rgb, lc.a);
        }
    }
    
    return base;
}

vec3 applySelectionHighlight(vec3 col, vec3 rd, vec3 n, float tt, float tm, float time) {
    float pulse = 0.5 + 0.5 * sin(time * 4.0);
    float rim = pow(1.0 - max(dot(-rd, n), 0.0), 2.0);
    
    vec3 hc;
    if (tt == TARGET_LIGHT) {
        hc = vec3(1.0, 0.9, 0.3);
    } else if (tm == TRANSFORM_TRANSLATE) {
        hc = vec3(0.3, 1.0, 0.4);
    } else if (tm == TRANSFORM_ROTATE) {
        hc = vec3(0.3, 0.5, 1.0);
    } else {
        hc = vec3(1.0, 0.5, 0.2);
    }
    
    col += hc * rim * (0.4 + 0.3 * pulse);
    return col * 1.15;
}
