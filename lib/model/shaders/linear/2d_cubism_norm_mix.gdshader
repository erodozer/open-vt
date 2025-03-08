// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2023 MizunagiKB <mizukb@live.jp>
// GDCubism shader: Mix
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

uniform vec4 color_base : source_color;
uniform vec4 color_screen : source_color;
uniform vec4 color_multiply : source_color;
uniform vec4 channel : source_color;
uniform sampler2D tex_main : filter_linear_mipmap;

void fragment() {
    vec4 color_tex = texture(tex_main, UV);
    color_tex.rgb = color_tex.rgb * color_multiply.rgb;

    // premul alpha
    color_tex.rgb = (color_tex.rgb + color_screen.rgb) - (color_tex.rgb * color_screen.rgb);
    vec4 color = color_tex * color_base;
    COLOR = vec4(color.rgb * color.a, color.a);
}
