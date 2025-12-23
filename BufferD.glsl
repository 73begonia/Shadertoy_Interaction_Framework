//=============================================================================
// Buffer D - 状态管理
//=============================================================================

#define IS_STATE_BUFFER

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = processStateBuffer(fragCoord, iResolution.xy, iMouse, iFrame, iTime, iChannel0, iChannel1);
}
