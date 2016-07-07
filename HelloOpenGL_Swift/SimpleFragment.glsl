uniform sampler2D Texture;
varying mediump vec2 CameraTextureCoord;
varying lowp vec4 DestinationColor;

void main(void) {
    mediump vec2 offset = 0.5 * vec2( cos(0.0), sin(0.0));
    mediump vec4 cr = texture2D(Texture, CameraTextureCoord + offset);
    mediump vec4 cga = texture2D(Texture, CameraTextureCoord);
    mediump vec4 cb = texture2D(Texture, CameraTextureCoord - offset);
//    gl_FragColor = vec4(0.5, 0.5, 0.5, 1.0);
//    gl_FragColor = vec4(cr.r, cga.g, cb.b, cga.a);
    gl_FragColor = vec4(DestinationColor.x * CameraTextureCoord.x, DestinationColor.y * CameraTextureCoord.y, DestinationColor.z, DestinationColor.w);
//    gl_FragColor = vec4(DestinationColor.x * (1.0 - CameraTextureCoord.x), DestinationColor.y * CameraTextureCoord.y, DestinationColor.z, DestinationColor.w);
//    gl_FragColor = DestinationColor;
}
