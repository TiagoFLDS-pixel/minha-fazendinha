shader_type canvas_item;

// Mostra a textura em tons de cinzento quando "cinza" = 1.0
// (itens bloqueados ou marcos ainda por receber).
uniform float cinza : hint_range(0.0, 1.0) = 1.0;
uniform float claridade : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec4 cor = texture(TEXTURE, UV);
	float l = dot(cor.rgb, vec3(0.299, 0.587, 0.114));
	vec3 cinzento = mix(vec3(l), vec3(1.0), claridade);
	COLOR = vec4(mix(cor.rgb, cinzento, cinza), cor.a);
}
