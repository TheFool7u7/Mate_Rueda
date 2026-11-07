/// Todos los textos visibles al usuario, centralizados en español.
/// Nunca hardcodear strings en los widgets directamente.
class AppStrings {
  AppStrings._();

  // ── General / App ──
  static const String appName = 'MateRueda';
  static const String loading = 'Cargando...';
  static const String error = 'Error';
  static const String ok = 'Aceptar';
  static const String cancel = 'Cancelar';
  static const String save = 'Guardar';
  static const String close = 'Cerrar';
  static const String back = 'Volver';
  static const String retry = 'Reintentar';

  // ── Splash ──
  static const String splashSubtitle = '¡Gira, juega y aprende matemática!';

  // ── Login ──
  static const String loginTitle = 'INICIAR SESIÓN';
  static const String emailHint = 'tucorreo@ejemplo.com';
  static const String emailLabel = 'Correo electrónico';
  static const String passwordHint = '••••••••••';
  static const String passwordLabel = 'Contraseña';
  static const String loginButton = 'INICIAR SESIÓN';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String orLoginWith = 'O inicia sesión con:';
  static const String createAccountButton = 'CREAR CUENTA';
  static const String noAccount = '¿No tienes cuenta?';

  // ── Registro ──
  static const String registerTitle = 'CREAR CUENTA';
  static const String usernameLabel = 'Nombre de usuario';
  static const String usernameHint = 'Ej: Alex_Games';
  static const String confirmPasswordLabel = 'Confirmar contraseña';
  static const String confirmPasswordHint = 'Repite tu contraseña';
  static const String registerButton = 'REGISTRARSE';
  static const String alreadyHaveAccount =
      '¡Inicia sesión si ya tienes cuenta!';

  // ── Cambiar Contraseña ──
  static const String changePasswordTitle = 'CAMBIAR CONTRASEÑA';
  static const String currentPasswordLabel = 'Contraseña actual';
  static const String newPasswordLabel = 'Nueva contraseña';
  static const String confirmNewPasswordLabel = 'Confirmar nueva contraseña';
  static const String saveChangesButton = 'GUARDAR CAMBIOS';
  static const String passwordChanged = 'Contraseña actualizada correctamente';

  // ── Home ──
  static const String createRoom = 'CREAR SALA';
  static const String joinRoom = 'UNIRSE A SALA';
  static const String howToPlay = 'CÓMO JUGAR';
  static const String settings = 'CONFIGURACIÓN';
  static const String topPlayers = 'TOP JUGADORES';

  // ── Crear Sala ──
  static const String createRoomTitle = 'CREAR SALA';
  static const String roomCode = 'Código de sala';
  static const String playerCount = 'Cantidad de jugadores';
  static const String responseTime = 'Tiempo de respuesta';
  static const String seconds = 'segundos';
  static const String shareCode = 'COMPARTIR CÓDIGO';
  static const String startGame = 'INICIAR JUEGO';
  static const String codeCopied = '¡Código copiado al portapapeles!';

  // ── Unirse a Sala ──
  static const String joinRoomTitle = 'UNIRSE A SALA';
  static const String enterCode = 'Ingresa el código de la sala';
  static const String askCodeHint = 'Pídele el código al creador de la sala';
  static const String joinButton = 'UNIRSE';
  static const String invalidCode = 'Código de sala inválido';
  static const String roomNotFound = 'Sala no encontrada';
  static const String roomFull = 'La sala está llena';

  // ── Lobby ──
  static const String lobbyTitle = 'ESPERANDO JUGADORES...';
  static const String playerReady = 'LISTO';
  static const String playerWaiting = 'Esperando...';
  static const String minPlayersRequired = 'Se necesitan al menos 2 jugadores';

  // ── Juego ──
  static const String category = 'CATEGORÍA';
  static const String waitingForAnswer = 'Esperando respuesta de';
  static const String sendAnswer = 'ENVIAR RESPUESTA';
  static const String typeYourAnswer = 'Escribe tu respuesta...';
  static const String letterAlreadyTaken = '¡Esa letra ya fue tomada!';
  static const String yourTurn = '¡Es tu turno!';
  static const String timeUp = '¡Se acabó el tiempo!';

  // ── Evaluación ──
  static const String evaluateTitle = 'CALIFICAR RESPUESTA';
  static const String numericRating = 'CALIFICACIÓN NUMÉRICA';
  static const String commonAnswer = 'RESPUESTA COMÚN';
  static const String excellentAnswer = 'RESPUESTA EXCELENTE';
  static const String surprisingAnswer = 'RESPUESTA SORPRENDENTE';

  // ── Castigos ──
  static const String punishmentTitle = '¡CASTIGO!';
  static const String selfiePunishment = '¡Tómate una selfie!';
  static const String singPunishment = '¡Canta una canción!';
  static const String findColorPunishment = '¡Encuentra algo de color';
  static const String takePhoto = 'TOMAR FOTO';
  static const String startRecording = 'INICIAR GRABACIÓN';
  static const String stopRecording = 'DETENER GRABACIÓN';
  static const String capture = 'CAPTURAR';

  // ── Resultados ──
  static const String resultsTitle = '¡RESULTADOS FINALES!';
  static const String mainMenu = 'MENÚ PRINCIPAL';
  static const String playAgain = 'REPETIR JUEGO';
  static const String points = 'pts';

  // ── Configuración ──
  static const String settingsTitle = 'CONFIGURACIÓN';
  static const String sound = 'Sonido';
  static const String vibration = 'Vibración';
  static const String notifications = 'Notificaciones';
  static const String changePassword = 'Cambiar contraseña';
  static const String logout = 'Cerrar sesión';
  static const String logoutConfirm =
      '¿Estás seguro de que deseas cerrar sesión?';

  // ── Validaciones ──
  static const String fieldRequired = 'Este campo es obligatorio';
  static const String invalidEmail = 'Ingresa un correo electrónico válido';
  static const String passwordTooShort =
      'La contraseña debe tener al menos 6 caracteres';
  static const String passwordsDoNotMatch = 'Las contraseñas no coinciden';
  static const String usernameTooShort =
      'El nombre de usuario debe tener al menos 3 caracteres';

  // ── Errores Firebase ──
  static const String authErrorGeneric =
      'Error de autenticación. Intenta de nuevo.';
  static const String authErrorWrongPassword = 'Contraseña incorrecta';
  static const String authErrorUserNotFound = 'Usuario no encontrado';
  static const String authErrorEmailInUse = 'Este correo ya está registrado';
  static const String authErrorWeakPassword = 'La contraseña es muy débil';
  static const String networkError = 'Error de conexión. Verifica tu internet.';

  // ── Navegación inferior (Home) ──
  static const String navHome = 'Inicio';
  static const String navStore = 'Tienda';
  static const String navFriends = 'Amigos';
  static const String navMessages = 'Mensajes';
  static const String navProfile = 'Perfil';

  // ── Power-ups ──
  static const String freezePowerUp = 'Congelar';
  static const String bombPowerUp = 'Bomba';
  static const String dicePowerUp = 'Dado';
  static const String wildcardPowerUp = 'Comodín';

  // ── Categorías de ejemplo ──
  // ── Categorías de ejemplo ──
  static const List<String> gameCategories = [
    'Nombre Masculino',
    'Nombre Femenino',
    'Animal',
    'País',
    'Ciudad',
    'Fruta',
    'Color',
    'Profesión',
    'Marca',
    'Película',
    'Comida',
    'Deporte',
  ];

  // ── Strings adicionales usados en pantallas ──

  // Auth
  static const String welcomeBack = '¡Bienvenido de vuelta!';
  static const String loginSubtitle = 'Inicia sesión para jugar';
  static const String login = 'INICIAR SESIÓN';
  static const String loggingIn = 'Iniciando sesión...';
  static const String register = 'REGISTRARSE';
  static const String createAccount = 'Crear cuenta';
  static const String createAccountTitle = 'CREAR CUENTA';
  static const String registerSubtitle = 'Regístrate y comienza a jugar';
  static const String creatingAccount = 'Creando tu cuenta...';
  static const String haveAccount = '¿Ya tienes cuenta?';
  static const String loginHere = 'Inicia sesión';
  static const String currentPassword = 'Contraseña actual';
  static const String newPassword = 'Nueva contraseña';
  static const String confirmNewPassword = 'Confirmar nueva contraseña';
  static const String resetEmailSent =
      'Se ha enviado un correo de recuperación';

  // Home
  static const String readyToPlay = '¿Listo para jugar?';
  static const String noPlayersYet = 'Aún no hay jugadores en el ranking';
  static const List<String> howToPlaySteps = [
    'Crea una sala y comparte el código con tus amigos, o únete a una sala existente ingresando el código.',
    'Al empezar la partida se muestra una categoría (ej. “Animal”) y una rueda con todas las letras del abecedario.',
    'Toca una letra libre para reclamarla — ¡sé rápido! Solo un jugador puede tomar cada letra.',
    'Una vez reclamada, escribe una palabra de esa categoría que empiece exactamente con la letra elegida. Tienes 30 segundos.',
    'Los demás jugadores califican tu respuesta del 1 al 10 y le otorgan una medalla: Común, Excelente o Sorprendente.',
    'La puntuación final es el promedio de los votos recibidos. ¡Respuestas creativas dan más puntos!',
    'Se juegan tantas rondas como letras haya. Al terminar, el jugador con MENOS puntos recibe un castigo: ¡selfie, buscar un color o cantar una canción!',
    '¡Gana quien acumule la mayor puntuación al final de todas las rondas!',
  ];

  // Room
  static const String creatingRoom = 'Creando sala...';
  static const String maxPlayersLabel = 'Jugadores';
  static const String timePerTurnLabel = 'Tiempo/turno';
  static const String createAndShare = 'CREAR Y COMPARTIR';
  static const String joiningRoom = 'Uniéndose a la sala...';
  static const String joinGame = 'UNIRSE AL JUEGO';
  static const String playersLabel = 'Jugadores';
  static const String waitingForPlayers = 'ESPERANDO...';
  static const String waitingForHost = 'Esperando que el host inicie...';
  static const String copyCode = 'Copiar código';
  static const String waitingPlayer = 'Esperando jugador...';

  // Game
  static const String typeYourWord = 'Escribe tu palabra...';
  static const String submitWord = 'ENVIAR PALABRA';
  static const String wordStartsWith = 'Una palabra que empiece con';

  // Evaluation
  static const String evaluateResponse = 'CALIFICAR RESPUESTA';
  static const String submitVote = 'ENVIAR VOTO';
  static const String voteSubmitted = '¡Voto enviado!';
  static const String waitingOtherVotes = 'Esperando otros votos...';
  static const String continueGame = 'CONTINUAR';
  static const String scoreLabel = 'Puntuación';

  // Punishment
  static const String recording = 'Grabando...';
  static const String recordingComplete = 'Grabación lista';
  static const String tapToRecord = 'Toca para grabar';
  static const String submitPunishment = 'ENVIAR CASTIGO';
  static const String skipPunishment = 'Saltar castigo';

  // Results
  static const String gameOver = '¡FIN DEL JUEGO!';

  // Settings
  static const String about = 'Acerca de';
}
