void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = renderScene(fragCoord, iResolution.xy, iTime, iChannel0);
}
