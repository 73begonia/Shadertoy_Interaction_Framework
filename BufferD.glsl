//=============================================================================
// Buffer D - 状态管理
//=============================================================================

#define IS_BUFFER_A

bool isKeyPressed(int keyCode) {
    return texelFetch(iChannel1, ivec2(keyCode, 0), 0).x > 0.0;
}

vec4 loadSelf(ivec2 p) {
    return texelFetch(iChannel0, p, 0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    ivec2 px = ivec2(fragCoord);
    
    int maxRow = ROW_LIGHT_PRM;
    int maxCol = max(MAX_PICKABLE_COUNT, MAX_LIGHT_COUNT) - 1;
    maxCol = max(maxCol, 3);
    
    if (px.y > maxRow || px.x > maxCol) {
        fragColor = vec4(0.0);
        return;
    }
    
    // 加载状态
    vec4 mouseState = loadSelf(ivec2(0, ROW_MOUSE));
    vec4 angles = loadSelf(ivec2(1, ROW_MOUSE));
    vec3 camDir = loadSelf(ivec2(2, ROW_MOUSE)).xyz;
    vec3 camPos = loadSelf(ivec2(3, ROW_MOUSE)).xyz;
    
    vec4 pickState = loadSelf(ivec2(0, ROW_SELECT));
    vec4 dragStartData = loadSelf(ivec2(1, ROW_SELECT));
    vec4 dragDepthData = loadSelf(ivec2(3, ROW_SELECT));
    
    float selectedId = pickState.x;
    float selectedType = pickState.y;
    float mode = pickState.z;
    float transformMode = pickState.w;
    float prevMouseDown = mouseState.z;
    
    vec4 prevKeyState = loadSelf(ivec2(0, ROW_KEYS));
    vec4 focusState = loadSelf(ivec2(1, ROW_KEYS));
    vec3 focusTarget = loadSelf(ivec2(2, ROW_KEYS)).xyz;
    vec4 focusAnglesData = loadSelf(ivec2(3, ROW_KEYS));
    vec4 prevKeyState2 = loadSelf(ivec2(4, ROW_KEYS));
    
    vec4 countsData = loadSelf(ivec2(0, ROW_COUNTS));
    vec3 focusStartPos = countsData.xyz;
    
    vec4 countsData2 = loadSelf(ivec2(1, ROW_COUNTS));
    int objectCount = int(countsData2.x);
    int lightCount = int(countsData2.y);
    
    bool isFocusing = focusState.x > 0.5;
    float focusProgress = focusState.y;
    bool showGizmos = focusState.z > 0.5;
    vec2 focusTargetAngles = focusAnglesData.xy;
    vec2 focusStartAngles = focusAnglesData.zw;
    
    bool prevKeyW = prevKeyState. x > 0.5;
    bool prevKeyE = prevKeyState. y > 0.5;
    bool prevKeyR = prevKeyState. z > 0.5;
    bool prevKeyF = prevKeyState. w > 0.5;
    bool prevKeyV = prevKeyState2.x > 0.5;
    
    bool currKeyW = isKeyPressed(KEY_W);
    bool currKeyE = isKeyPressed(KEY_E);
    bool currKeyR = isKeyPressed(KEY_R);
    bool currKeyF = isKeyPressed(KEY_F);
    bool currKeyV = isKeyPressed(KEY_V);
    bool currKeyDel = isKeyPressed(KEY_DELETE);
    
    bool keyWJustPressed = currKeyW && !prevKeyW;
    bool keyEJustPressed = currKeyE && !prevKeyE;
    bool keyRJustPressed = currKeyR && ! prevKeyR;
    bool keyFJustPressed = currKeyF && !prevKeyF;
    bool keyVJustPressed = currKeyV && !prevKeyV;
    
    // 物体数据
    float types[MAX_PICKABLE_COUNT];
    vec3 positions[MAX_PICKABLE_COUNT];
    vec3 scales[MAX_PICKABLE_COUNT];
    vec3 colors[MAX_PICKABLE_COUNT];
    mat3 rotationMats[MAX_PICKABLE_COUNT];
    
    for (int i = 0; i < MAX_PICKABLE_COUNT; i++) {
        vec4 d = loadSelf(ivec2(i, ROW_OBJ_POS));
        types[i] = d. w;
        positions[i] = d. xyz;
        scales[i] = loadSelf(ivec2(i, ROW_OBJ_SCALE)).xyz;
        colors[i] = loadSelf(ivec2(i, ROW_OBJ_COLOR)).xyz;
        rotationMats[i] = mat3(
            loadSelf(ivec2(i, ROW_OBJ_ROT0)).xyz,
            loadSelf(ivec2(i, ROW_OBJ_ROT1)).xyz,
            loadSelf(ivec2(i, ROW_OBJ_ROT2)).xyz
        );
    }
    
    // 光源数据
    float lightTypes[MAX_LIGHT_COUNT];
    vec3 lightPositions[MAX_LIGHT_COUNT];
    vec3 lightDirections[MAX_LIGHT_COUNT];
    vec3 lightColors[MAX_LIGHT_COUNT];
    float lightIntensities[MAX_LIGHT_COUNT];
    float lightRanges[MAX_LIGHT_COUNT];
    float lightAngles[MAX_LIGHT_COUNT];
    vec2 lightAreaSizes[MAX_LIGHT_COUNT];
    
    for (int i = 0; i < MAX_LIGHT_COUNT; i++) {
        vec4 pos = loadSelf(ivec2(i, ROW_LIGHT_POS));
        lightTypes[i] = pos.w;
        lightPositions[i] = pos.xyz;
        vec4 dir = loadSelf(ivec2(i, ROW_LIGHT_DIR));
        lightDirections[i] = dir.xyz;
        lightAngles[i] = dir.w;
        vec4 col = loadSelf(ivec2(i, ROW_LIGHT_COL));
        lightColors[i] = col.xyz;
        lightIntensities[i] = col.w;
        vec4 prm = loadSelf(ivec2(i, ROW_LIGHT_PRM));
        lightRanges[i] = prm.x;
        lightAreaSizes[i] = prm. yz;
    }
    
    // 初始化
    if (iFrame == 0) {
        if (px.y == ROW_MOUSE) {
            if (px.x == 0) fragColor = vec4(0.0);
            else if (px.x == 1) fragColor = vec4(0.0);
            else if (px. x == 2) fragColor = vec4(0.0, 0.0, 1.0, 0.0);
            else fragColor = vec4(INITIAL_CAM_POS, 1.0);
        }
        else if (px.y == ROW_SELECT) {
            if (px.x == 0) fragColor = vec4(-1.0, TARGET_OBJECT, MODE_NONE, TRANSFORM_TRANSLATE);
            else fragColor = vec4(0.0);
        }
        else if (px. y == ROW_KEYS) {
            if (px. x == 1) fragColor = vec4(0.0, 0.0, 1.0, 0.0); // showGizmos = true
            else fragColor = vec4(0.0);
        }
        else if (px.y == ROW_COUNTS) {
            if (px.x == 0) fragColor = vec4(0.0);
            else if (px.x == 1) fragColor = vec4(2.0, 1.0, 0.0, 0.0);
            else fragColor = vec4(0.0);
        }
        else if (px.y == ROW_OBJ_POS) {
            if (px. x == 0) fragColor = vec4(-0.5, -1.4, -0.5, OBJ_TYPE_SPHERE);
            else if (px.x == 1) fragColor = vec4(0.5, -0.8, 0.5, OBJ_TYPE_BOX);
            else fragColor = vec4(0.0, 0.0, 0.0, OBJ_TYPE_NONE);
        }
        else if (px.y == ROW_OBJ_SCALE) {
            fragColor = vec4(1.0, 1.0, 1.0, 0.0);
        }
        else if (px.y == ROW_OBJ_COLOR) {
            if (px.x == 0) fragColor = vec4(0.9, 0.6, 0.3, 0.0);
            else if (px.x == 1) fragColor = vec4(0.3, 0.6, 0.9, 0.0);
            else fragColor = vec4(0.5, 0.5, 0.5, 0.0);
        }
        else if (px.y == ROW_OBJ_ROT0) { fragColor = vec4(1.0, 0.0, 0.0, 0.0); }
        else if (px.y == ROW_OBJ_ROT1) { fragColor = vec4(0.0, 1.0, 0.0, 0.0); }
        else if (px.y == ROW_OBJ_ROT2) { fragColor = vec4(0.0, 0.0, 1.0, 0.0); }
        else if (px.y == ROW_LIGHT_POS) {
            if (px.x == 0) fragColor = vec4(0.0, 1.5, -1.0, LIGHT_TYPE_POINT);
            else fragColor = vec4(0.0, 0.0, 0.0, LIGHT_TYPE_NONE);
        }
        else if (px.y == ROW_LIGHT_DIR) {
            fragColor = vec4(0.0, -1.0, 0.0, 0.5);
        }
        else if (px.y == ROW_LIGHT_COL) {
            if (px.x == 0) fragColor = vec4(1.0, 1.0, 0.9, 3.0);
            else fragColor = vec4(1.0, 1.0, 1.0, 1.0);
        }
        else if (px.y == ROW_LIGHT_PRM) {
            fragColor = vec4(8.0, 1.0, 1.0, 0.0);
        }
        else {
            fragColor = vec4(0.0);
        }
        return;
    }
    
    // 构建矩阵
    float aspect = iResolution.x / iResolution. y;
    mat4 PInv = perspectiveInv(radians(fov), aspect, near, far);
    mat4 VInv = lookAtInv(camPos, camPos + camDir, vec3(0.0, 1.0, 0.0));
    
    bool mouseDown = iMouse.z > 0.0;
    bool mouseJustPressed = mouseDown && (prevMouseDown < 0.5);
    bool mouseJustReleased = ! mouseDown && (prevMouseDown > 0.5);
    
    vec2 mouseUV = iMouse.xy / iResolution. xy;
    vec3 rayDir = createRayDir(mouseUV, PInv, VInv);
    
    bool hasSelection = (selectedId >= 0.0);
    
    // 构建数组
    Transform transforms[MAX_PICKABLE_COUNT];
    for (int i = 0; i < MAX_PICKABLE_COUNT; i++) {
        transforms[i]. type = types[i];
        transforms[i].position = positions[i];
        transforms[i].rotation = rotationMats[i];
        transforms[i].scale = scales[i];
        transforms[i].color = colors[i];
    }
    
    Light lights[MAX_LIGHT_COUNT];
    for (int i = 0; i < MAX_LIGHT_COUNT; i++) {
        lights[i].type = lightTypes[i];
        lights[i]. position = lightPositions[i];
        lights[i].direction = lightDirections[i];
        lights[i].color = lightColors[i];
        lights[i].intensity = lightIntensities[i];
        lights[i].range = lightRanges[i];
        lights[i].angle = lightAngles[i];
        lights[i]. areaSize = lightAreaSizes[i];
    }
    
    // UI检测
    int uiAction = UI_NONE;
    if (mouseJustPressed) {
        uiAction = checkUIClick(iMouse.xy, int(selectedId), selectedType, iResolution.xy);
    }
    
    // V键切换线框显示
    if (keyVJustPressed) {
        showGizmos = ! showGizmos;
    }
    
    // 聚焦动画
    bool shouldStartFocus = false;
    
    if (isFocusing) {
        focusProgress += FOCUS_SPEED;
        if (focusProgress >= 1.0) {
            focusProgress = 1.0;
            isFocusing = false;
        }
        
        float t = smootherStep(focusProgress);
        camPos = mix(focusStartPos, focusTarget, t);
        
        vec2 deltaAngles = focusTargetAngles - focusStartAngles;
        if (deltaAngles. y > PI) deltaAngles.y -= TAU;
        if (deltaAngles. y < -PI) deltaAngles.y += TAU;
        
        angles. xy = focusStartAngles + deltaAngles * t;
        angles.zw = angles.xy;
        camDir = anglesToDirection(angles.xy);
        
        if (focusProgress > 0.2) {
            if (mouseDown && ! mouseJustPressed) isFocusing = false;
        }
        if (isKeyPressed(KEY_A) || isKeyPressed(KEY_S) || isKeyPressed(KEY_D)) isFocusing = false;
        if (isKeyPressed(KEY_W) && !hasSelection) isFocusing = false;
    }
    
    // 键盘切换模式
    if (hasSelection && ! isFocusing) {
        if (keyWJustPressed) transformMode = TRANSFORM_TRANSLATE;
        if (keyEJustPressed) transformMode = TRANSFORM_ROTATE;
        if (keyRJustPressed) transformMode = TRANSFORM_SCALE;
    }
    
    // 交互
    vec3 frameDelta = vec3(0.0);
    mat3 frameRotation = mat3(1.0);
    bool applyRotation = false;
    
    if (! isFocusing) {
        if (mouseJustPressed) {
            if (uiAction == UI_ADD_SPHERE && objectCount < MAX_PICKABLE_COUNT) {
                int id = objectCount;
                types[id] = OBJ_TYPE_SPHERE;
                positions[id] = camPos + camDir * 3.0;
                scales[id] = vec3(1.0);
                colors[id] = randomColor(iFrame + id);
                rotationMats[id] = mat3(1.0);
                objectCount++;
                selectedId = float(id);
                selectedType = TARGET_OBJECT;
                transformMode = TRANSFORM_TRANSLATE;
            }
            else if (uiAction == UI_ADD_BOX && objectCount < MAX_PICKABLE_COUNT) {
                int id = objectCount;
                types[id] = OBJ_TYPE_BOX;
                positions[id] = camPos + camDir * 3.0;
                scales[id] = vec3(1.0);
                colors[id] = randomColor(iFrame + id + 50);
                rotationMats[id] = mat3(1.0);
                objectCount++;
                selectedId = float(id);
                selectedType = TARGET_OBJECT;
                transformMode = TRANSFORM_TRANSLATE;
            }
            else if (uiAction == UI_ADD_POINT_LIGHT && lightCount < MAX_LIGHT_COUNT) {
                int id = lightCount;
                lightTypes[id] = LIGHT_TYPE_POINT;
                lightPositions[id] = camPos + camDir * 3.0;
                lightDirections[id] = vec3(0.0, -1.0, 0.0);
                lightColors[id] = vec3(1.0, 0.95, 0.8);
                lightIntensities[id] = 2.0;
                lightRanges[id] = 8.0;
                lightAngles[id] = 0.5;
                lightAreaSizes[id] = vec2(1.0);
                lightCount++;
                selectedId = float(id);
                selectedType = TARGET_LIGHT;
                transformMode = TRANSFORM_TRANSLATE;
            }
            else if (uiAction == UI_ADD_SPOT_LIGHT && lightCount < MAX_LIGHT_COUNT) {
                int id = lightCount;
                lightTypes[id] = LIGHT_TYPE_SPOT;
                lightPositions[id] = camPos + camDir * 3.0;
                lightDirections[id] = normalize(vec3(0.0, -1.0, 0.3));
                lightColors[id] = vec3(1.0, 0.9, 0.7);
                lightIntensities[id] = 3.0;
                lightRanges[id] = 10.0;
                lightAngles[id] = 0.4;
                lightAreaSizes[id] = vec2(1.0);
                lightCount++;
                selectedId = float(id);
                selectedType = TARGET_LIGHT;
                transformMode = TRANSFORM_TRANSLATE;
            }
            else if (uiAction == UI_ADD_AREA_LIGHT && lightCount < MAX_LIGHT_COUNT) {
                int id = lightCount;
                lightTypes[id] = LIGHT_TYPE_AREA;
                lightPositions[id] = camPos + camDir * 3.0;
                lightDirections[id] = normalize(vec3(0.0, -1.0, 0.0));
                lightColors[id] = vec3(1.0, 1.0, 0.95);
                lightIntensities[id] = 2.5;
                lightRanges[id] = 10.0;
                lightAngles[id] = 0.5;
                lightAreaSizes[id] = vec2(1.0, 0.6);
                lightCount++;
                selectedId = float(id);
                selectedType = TARGET_LIGHT;
                transformMode = TRANSFORM_TRANSLATE;
            }
            else if (uiAction == UI_DELETE && hasSelection) {
                int id = int(selectedId);
                if (selectedType == TARGET_OBJECT) {
                    types[id] = OBJ_TYPE_NONE;
                } else {
                    lightTypes[id] = LIGHT_TYPE_NONE;
                }
                selectedId = -1.0;
                mode = MODE_NONE;
            }
            else if (uiAction == UI_MODE_TRANSLATE && hasSelection) {
                transformMode = TRANSFORM_TRANSLATE;
            }
            else if (uiAction == UI_MODE_ROTATE && hasSelection) {
                transformMode = TRANSFORM_ROTATE;
            }
            else if (uiAction == UI_MODE_SCALE && hasSelection) {
                transformMode = TRANSFORM_SCALE;
            }
            else if (uiAction == UI_FOCUS && hasSelection) {
                shouldStartFocus = true;
            }
            else if (uiAction == UI_NONE) {
                for (int i = 0; i < MAX_PICKABLE_COUNT; i++) {
                    transforms[i].type = types[i];
                    transforms[i].position = positions[i];
                }
                for (int i = 0; i < MAX_LIGHT_COUNT; i++) {
                    lights[i].type = lightTypes[i];
                    lights[i].position = lightPositions[i];
                    lights[i].direction = lightDirections[i];
                    lights[i].angle = lightAngles[i];
                    lights[i].areaSize = lightAreaSizes[i];
                }
                
                Ray ray = Ray(camPos, rayDir);
                HitResult hit = pickScene(ray, transforms, objectCount, lights, lightCount);
                
                if (hit. hit && hit.objectId >= 0) {
                    selectedId = float(hit.objectId);
                    selectedType = hit.targetType;
                    mode = MODE_TRANSFORM;
                    dragStartData. xy = iMouse.xy;
                    
                    if (transformMode == TRANSFORM_TRANSLATE) {
                        dragDepthData = vec4(hit.t, hit.hitPoint);
                    } else if (transformMode == TRANSFORM_SCALE && selectedType == TARGET_OBJECT) {
                        int id = hit.objectId;
                        dragStartData.z = (scales[id].x + scales[id].y + scales[id].z) / 3.0;
                    } else if (transformMode == TRANSFORM_SCALE && selectedType == TARGET_LIGHT) {
                        int id = hit.objectId;
                        dragStartData.z = lightRanges[id];
                        dragStartData.w = (lightAreaSizes[id]. x + lightAreaSizes[id].y) / 2.0;
                    }
                } else {
                    selectedId = -1.0;
                    mode = MODE_CAMERA;
                    mouseState. xy = iMouse. xy;
                    angles. zw = angles.xy;
                }
            }
        }
        else if (mouseDown && mode != MODE_NONE) {
            if (mode == MODE_CAMERA) {
                vec2 delta = iMouse. xy - mouseState.xy;
                angles.x = angles.z + delta.y / iResolution.y * MOUSE_SENSITIVITY_Y;
                angles. x = clamp(angles.x, -1.4, 1.4);
                angles. y = angles.w - delta.x / iResolution.x * MOUSE_SENSITIVITY_X;
                angles.y = mod(angles.y, TAU);
                camDir = anglesToDirection(angles.xy);
            }
            else if (mode == MODE_TRANSFORM && hasSelection) {
                int id = int(selectedId);
                vec2 mouseDelta = iMouse.xy - dragStartData.xy;
                
                if (transformMode == TRANSFORM_TRANSLATE) {
                    vec3 planeNormal = -camDir;
                    vec3 planePoint = dragDepthData. yzw;
                    vec3 currentPoint = rayPlaneIntersect(camPos, rayDir, planePoint, planeNormal);
                    frameDelta = currentPoint - planePoint;
                    dragDepthData. yzw = currentPoint;
                }
                else if (transformMode == TRANSFORM_ROTATE) {
                    float deltaX = (iMouse.x - dragStartData. x) / iResolution.x * PI * ROTATE_SENSITIVITY;
                    float deltaY = (iMouse.y - dragStartData.y) / iResolution.y * PI * ROTATE_SENSITIVITY;
                    dragStartData.xy = iMouse. xy;
                    
                    if (selectedType == TARGET_OBJECT) {
                        bool shiftPressed = isKeyPressed(KEY_SHIFT);
                        if (shiftPressed) {
                            frameRotation = rotateZ3(deltaX);
                        } else {
                            frameRotation = rotateY3(-deltaX) * rotateX3(-deltaY);
                        }
                        applyRotation = true;
                    } else {
                        mat3 rot = rotateY3(-deltaX) * rotateX3(-deltaY);
                        lightDirections[id] = normalize(rot * lightDirections[id]);
                    }
                }
                else if (transformMode == TRANSFORM_SCALE) {
                    float scaleFactor = 1.0 + mouseDelta.y / iResolution.y * SCALE_SENSITIVITY;
                    scaleFactor = clamp(scaleFactor, 0.1, 10.0);
                    
                    if (selectedType == TARGET_OBJECT) {
                        float targetScale = dragStartData.z * scaleFactor;
                        targetScale = clamp(targetScale, 0.1, 5.0);
                        float avgScale = (scales[id].x + scales[id].y + scales[id].z) / 3.0;
                        frameDelta = vec3(targetScale - avgScale);
                    } else {
                        lightRanges[id] = clamp(dragStartData.z * scaleFactor, 1.0, 30.0);
                        if (lightTypes[id] == LIGHT_TYPE_AREA) {
                            float areaScale = dragStartData.w * scaleFactor;
                            lightAreaSizes[id] = clamp(vec2(areaScale * 1.67, areaScale), vec2(0.2), vec2(5.0));
                        }
                    }
                }
            }
        }
        else if (mouseJustReleased) {
            mode = MODE_NONE;
            angles.zw = angles.xy;
        }
        
        if (keyFJustPressed && hasSelection) {
            shouldStartFocus = true;
        }
        
        if (currKeyDel && hasSelection) {
            int id = int(selectedId);
            if (selectedType == TARGET_OBJECT) {
                types[id] = OBJ_TYPE_NONE;
            } else {
                lightTypes[id] = LIGHT_TYPE_NONE;
            }
            selectedId = -1.0;
            mode = MODE_NONE;
        }
        
        if (! hasSelection) {
            vec3 Eye = camDir;
            vec3 Tan = normalize(cross(vec3(Eye.x, 0.0, Eye.z), vec3(0.0, 1.0, 0.0)));
            if (length(vec3(Eye.x, 0.0, Eye.z)) < 0.01) Tan = vec3(1.0, 0.0, 0.0);
            
            float speed = MOVE_SPEED;
            if (isKeyPressed(KEY_SHIFT)) speed *= SPRINT_MULTIPLIER;
            
            if (isKeyPressed(KEY_W)) camPos += Eye * speed;
            if (isKeyPressed(KEY_S)) camPos -= Eye * speed;
            if (isKeyPressed(KEY_A)) camPos -= Tan * speed;
            if (isKeyPressed(KEY_D)) camPos += Tan * speed;
            if (isKeyPressed(KEY_SPACE)) camPos.y += speed;
            if (isKeyPressed(KEY_CTRL)) camPos.y -= speed;
        }
    }
    
    // 启动聚焦
    if (shouldStartFocus && hasSelection) {
        int id = int(selectedId);
        vec3 objCenter;
        float objSize;
        
        if (selectedType == TARGET_OBJECT) {
            objCenter = positions[id];
            objSize = (scales[id].x + scales[id]. y + scales[id].z) / 3.0;
        } else {
            objCenter = lightPositions[id];
            objSize = 0.5;
        }
        
        float distance = max(FOCUS_DISTANCE, objSize * 2.5);
        vec3 viewDir = normalize(objCenter - camPos);
        
        focusTarget = objCenter - viewDir * distance;
        focusTargetAngles = directionToAngles(viewDir);
        focusStartPos = camPos;
        focusStartAngles = angles. xy;
        
        isFocusing = true;
        focusProgress = 0.0;
    }
    
    // 应用变换
    if (mode == MODE_TRANSFORM && hasSelection && ! isFocusing) {
        int id = int(selectedId);
        if (selectedType == TARGET_OBJECT) {
            if (transformMode == TRANSFORM_TRANSLATE) {
                positions[id] += frameDelta;
            } else if (transformMode == TRANSFORM_ROTATE && applyRotation) {
                rotationMats[id] = frameRotation * rotationMats[id];
            } else if (transformMode == TRANSFORM_SCALE) {
                scales[id] += frameDelta;
                scales[id] = clamp(scales[id], vec3(0.1), vec3(5.0));
            }
        } else {
            if (transformMode == TRANSFORM_TRANSLATE) {
                lightPositions[id] += frameDelta;
            }
        }
    }
    
    // 输出
    if (px.y == ROW_MOUSE) {
        if (px.x == 0) fragColor = vec4(mouseState.xy, mouseDown ?  1.0 : 0.0, 0.0);
        else if (px.x == 1) fragColor = angles;
        else if (px.x == 2) fragColor = vec4(camDir, 0.0);
        else fragColor = vec4(camPos, 1.0);
    }
    else if (px.y == ROW_SELECT) {
        if (px.x == 0) fragColor = vec4(selectedId, selectedType, mode, transformMode);
        else if (px.x == 1) fragColor = dragStartData;
        else if (px. x == 3) fragColor = dragDepthData;
        else fragColor = vec4(0.0);
    }
    else if (px. y == ROW_KEYS) {
        if (px.x == 0) fragColor = vec4(currKeyW ?  1.0 : 0.0, currKeyE ? 1.0 : 0.0, currKeyR ? 1.0 : 0.0, currKeyF ? 1.0 : 0.0);
        else if (px.x == 1) fragColor = vec4(isFocusing ? 1.0 : 0.0, focusProgress, showGizmos ?  1.0 : 0.0, 0.0);
        else if (px.x == 2) fragColor = vec4(focusTarget, 0.0);
        else if (px. x == 3) fragColor = vec4(focusTargetAngles, focusStartAngles);
        else if (px.x == 4) fragColor = vec4(currKeyV ? 1.0 : 0.0, 0.0, 0.0, 0.0);
        else fragColor = vec4(0.0);
    }
    else if (px.y == ROW_COUNTS) {
        if (px.x == 0) fragColor = vec4(focusStartPos, 0.0);
        else if (px.x == 1) fragColor = vec4(float(objectCount), float(lightCount), 0.0, 0.0);
        else fragColor = vec4(0.0);
    }
    else if (px.y == ROW_OBJ_POS) {
        if (px.x < MAX_PICKABLE_COUNT) fragColor = vec4(positions[px.x], types[px.x]);
        else fragColor = vec4(0.0, 0.0, 0.0, OBJ_TYPE_NONE);
    }
    else if (px.y == ROW_OBJ_SCALE) {
        if (px.x < MAX_PICKABLE_COUNT) fragColor = vec4(scales[px.x], 0.0);
        else fragColor = vec4(1.0, 1.0, 1.0, 0.0);
    }
    else if (px.y == ROW_OBJ_COLOR) {
        if (px.x < MAX_PICKABLE_COUNT) fragColor = vec4(colors[px.x], 0.0);
        else fragColor = vec4(0.5, 0.5, 0.5, 0.0);
    }
    else if (px.y == ROW_OBJ_ROT0) {
        if (px.x < MAX_PICKABLE_COUNT) fragColor = vec4(rotationMats[px.x][0], 0.0);
        else fragColor = vec4(1.0, 0.0, 0.0, 0.0);
    }
    else if (px. y == ROW_OBJ_ROT1) {
        if (px. x < MAX_PICKABLE_COUNT) fragColor = vec4(rotationMats[px.x][1], 0.0);
        else fragColor = vec4(0.0, 1.0, 0.0, 0.0);
    }
    else if (px. y == ROW_OBJ_ROT2) {
        if (px. x < MAX_PICKABLE_COUNT) fragColor = vec4(rotationMats[px.x][2], 0.0);
        else fragColor = vec4(0.0, 0.0, 1.0, 0.0);
    }
    else if (px. y == ROW_LIGHT_POS) {
        if (px.x < MAX_LIGHT_COUNT) fragColor = vec4(lightPositions[px. x], lightTypes[px.x]);
        else fragColor = vec4(0.0, 0.0, 0.0, LIGHT_TYPE_NONE);
    }
    else if (px.y == ROW_LIGHT_DIR) {
        if (px.x < MAX_LIGHT_COUNT) fragColor = vec4(lightDirections[px. x], lightAngles[px.x]);
        else fragColor = vec4(0.0, -1.0, 0.0, 0.5);
    }
    else if (px.y == ROW_LIGHT_COL) {
        if (px.x < MAX_LIGHT_COUNT) fragColor = vec4(lightColors[px.x], lightIntensities[px.x]);
        else fragColor = vec4(1.0, 1.0, 1.0, 1.0);
    }
    else if (px.y == ROW_LIGHT_PRM) {
        if (px.x < MAX_LIGHT_COUNT) fragColor = vec4(lightRanges[px. x], lightAreaSizes[px. x], 0.0);
        else fragColor = vec4(8.0, 1.0, 1.0, 0.0);
    }
    else {
        fragColor = vec4(0.0);
    }
}
