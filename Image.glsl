void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    FrameState state = loadFrameState(iChannel0);
    
    float aspect = iResolution.x / iResolution. y;
    mat4 PInv = perspectiveInv(radians(fov), aspect, near, far);
    mat4 VInv = lookAtInv(state.camPos, state.camPos + state.camDir, vec3(0.0, 1.0, 0.0));
    
    mat4 view = lookAt(state.camPos, state.camPos + state.camDir, vec3(0.0, 1.0, 0.0));
    mat4 proj = perspective(radians(fov), aspect, near, far);
    mat4 viewProj = proj * view;
    
    vec2 uv = fragCoord / iResolution.xy;
    vec3 rayDir = createRayDir(uv, PInv, VInv);
    Ray ray = Ray(state.camPos, rayDir);
    
    HitResult hit = traceScene(ray, state. transforms, state.objectCount, state.lights, state.lightCount);
    
    vec3 color;
    if (hit.hit) {
        if (hit.targetType == TARGET_LIGHT) {
            color = hit.material.color * 2.0;
        } else {
            // 传入 transforms 用于阴影检测
            color = calculateLighting(hit.hitPoint, hit.normal, state.camPos, hit.material, 
                                       state.lights, state.lightCount,
                                       state.transforms, state. objectCount);
        }
        
        if (hit.objectId >= 0 && hit.objectId == state.selectedId && 
            hit.targetType == state.selectedType) {
            color = applySelectionHighlight(color, rayDir, hit.normal, 
                                            state.selectedType, state.transformMode, iTime);
        }
    } else {
        color = vec3(0.02, 0.02, 0.05);
    }
    
    // 先Gamma校正场景
    color = pow(color, vec3(0.4545));
    
    // 再绘制线框和UI（不受光照影响）
    color = renderLightGizmos(fragCoord, state, viewProj, iResolution. xy, color);
    color = renderUI(fragCoord, state, iTime, iResolution.xy, color);
    
    fragColor = vec4(color, 1.0);
}
