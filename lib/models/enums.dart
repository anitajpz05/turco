/// Enumeraciones del dominio de Turco.
library;

enum Categoria {
  corte('Corte', 'assets/images/categorias/corte.png'),
  color('Color', 'assets/images/categorias/color.png'),
  barba('Barba', 'assets/images/categorias/barba.png'),
  peinado('Peinado', 'assets/images/categorias/peinado.png'),
  tratamiento('Tratamiento', 'assets/images/categorias/tratamiento.png');

  const Categoria(this.etiqueta, this.imagen);
  final String etiqueta;
  final String imagen;
}

enum Publico {
  mujeres('Mujeres'),
  hombres('Hombres'),
  unisex('Unisex');

  const Publico(this.etiqueta);
  final String etiqueta;
}

enum Genero {
  mujer('Mujer'),
  hombre('Hombre');

  const Genero(this.etiqueta);
  final String etiqueta;

  /// Público que corresponde por defecto a un cliente de este género.
  Publico get publico => this == Genero.mujer ? Publico.mujeres : Publico.hombres;
}

enum EstadoTurno {
  programado('Programado'),
  completado('Completado'),
  cancelado('Cancelado');

  const EstadoTurno(this.etiqueta);
  final String etiqueta;
}

/// Filtro por público usado en formularios y catálogo (Todos, Mujeres, Hombres).
enum FiltroPublico {
  todos('Todos'),
  mujeres('Mujeres'),
  hombres('Hombres');

  const FiltroPublico(this.etiqueta);
  final String etiqueta;

  /// Un servicio unisex aparece tanto en Mujeres como en Hombres.
  bool admite(Publico p) => switch (this) {
    FiltroPublico.todos => true,
    FiltroPublico.mujeres => p != Publico.hombres,
    FiltroPublico.hombres => p != Publico.mujeres,
  };

  static FiltroPublico desdeGenero(Genero g) => g == Genero.mujer ? FiltroPublico.mujeres : FiltroPublico.hombres;
}

/// Filtro por género en la pantalla Clientes.
enum FiltroGenero {
  todos('Todos'),
  mujeres('Mujeres'),
  hombres('Hombres');

  const FiltroGenero(this.etiqueta);
  final String etiqueta;

  bool admite(Genero g) => switch (this) {
    FiltroGenero.todos => true,
    FiltroGenero.mujeres => g == Genero.mujer,
    FiltroGenero.hombres => g == Genero.hombre,
  };
}
