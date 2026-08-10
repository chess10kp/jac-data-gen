"""
	bin(numero) obtiene el valor binario de numero
	[2:] obtiene los elementos de del binario anterior excepto los primeros 2, por ejemplo 11000000[2:] regresa 000000
	zfill(8) rellena con ceros a la izquiera el valor anterior hasta que este tenga longitud 8, por ejemplo 111111 regresa 00111111
	"""
def obtenerBinario(numero: int) -> str {
    bin(numero)[2:].zfill(8)
}