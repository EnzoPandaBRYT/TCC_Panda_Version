extends CharacterBody2D

# Faz com que o AnimatedSprite2D esteja sempre pronto para uso em qualquer parte do código
# Isso evita com que a animação não seja carregada
@onready var anim: AnimatedSprite2D = $anim

# Velocidade CONSTANTE do jogador
const SPEED = 300.0

# Velocidade do Pulo do Jogador
const JUMP_VELOCITY = -400.0

# Estabelece o número máximo de Pulos Máximos do jogador
# De início, o número de pulos máximos é 1
var maxJumps = 1

# Pulo Duplo:
var doubleJump = false

# Pulando
var isJumping = false

# Determina se o jogador possuí o controle do FLUXO TEMPORAL
var timeWarp = false

# Fator padrão de tempo (Metade do tempo)
var factor = 0.5

# Verifica se o FLUXO TEMPORAL foi alterado ou não
var timeWarpActivated = false

# Recarrega a habilidade do TIME WARP
# Inicialmente verdadeira, deverá esperar a recarga inicial primeiro
var twReloading = false

# Processo executado a CADA FRAME possível do jogo
func _physics_process(delta: float) -> void:
	
	
	# Adiciona a gravidade - Padrão: 980.0 px/s
	if not is_on_floor():
		isJumping = false # Verifica se o jogador está pulando
		velocity += get_gravity() * delta # Velocidade de gravidade do projeto (Padrão) * Frames possíveis
	
	if is_on_floor() and doubleJump == true:
		maxJumps = 2 # Pulos máximos = 2 (Apenas para verificação)
	
	# DEV_TOOL = HOME no teclado; Libera todo tipo de mecânica possível
	if Input.is_action_just_pressed("DEV_TOOL") and is_on_floor():
		doubleJump = true # Libera o Pulo Duplo e Time Warp (DEV TOOL)
		timeWarp = true
		print("Double Jump; Time Warp desbloqueado!")
		
		print("- Double Jump = Pule no AR!")
		print("- Time Warp = Pressione L para diminuir o FLUXO TEMPORAL")
	
	# Tecla L pressionada ativa o Time Warp
	# Impossível ativar múltiplas vezes
	# TODO: Cooldown entre as ativações
	if Input.is_action_just_pressed("time_warp") and timeWarp == true and twReloading == false and timeWarpActivated == false:
		timeWarpActivated = true
		await slow_motion()
		
	
	# Verifica a tecla de pulo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		isJumping = true # Atualiza o verificador de pulo
		velocity.y = JUMP_VELOCITY # Utiliza velocidade para não "teleportar" o jogador para cima
	
	# Permite o Pulo Duplo, se liberado
	if Input.is_action_just_pressed("jump") and not is_on_floor() and maxJumps == 2:
		velocity.y = JUMP_VELOCITY * 0.8 # Indica que o segundo pulo será menor
		maxJumps = 0 # Zera o contador de pulos máximos para garantir que o jogador não irá sair voando
	
	# Detecta a ação de STOMPAR
	if Input.is_action_just_pressed("stomp") and not is_on_floor():
		velocity += get_gravity() * 0.5 # Ação de descer mais rápido, diminui o efeito da gravidade para melhores efeitos
		anim.flip_v = true
		anim.play("jump")

	# Pega o INPUT da direção do jogador e com isso, o movimenta pelo cenário
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Detecta movimentação para mudar o sprite
	if is_on_floor():
		if direction > 0 and not isJumping:
			anim.flip_h = false # Olhando para a direita
			anim.play("moving") # Toca a animação de Mover
		elif direction < 0 and not isJumping:
			anim.flip_h = true # Olhando para a esquerda
			anim.play("moving") # Toca a animação de Mover, porém espelhada
		elif isJumping:
			anim.flip_v = false # Determina que não é para virar o sprite de pulo
			anim.play("jump") # Toca a animação de Pulo; A verificação do pulo é feita na ação do pulo
		else:
			anim.play("idle") # Caso nenhuma das animações acima seja executada, entrará em estado "inerte"
	move_and_slide()

func slow_motion(duration: float = 1.5):
	print("Time Warp começou agora fazendo alteraçãoes")
	Engine.time_scale = factor # Determina a escala de tempo da Engine, isso inclui TODOS os nós
	await get_tree().create_timer(duration, false, false, true).timeout # Cria um timer assíncrono que não será processado sempre, afetado por Física, e nem pelo Time Factor do jogo
	print("Time Warp Acabou")
	timeWarpActivated = false
	twReloading = true
	Engine.time_scale = 1.0
	
	if twReloading == true:
		print("Recarregando...")
		await get_tree().create_timer(duration * 2, false, false, true).timeout
		twReloading = false
		print("Recarregado!")
	
	
