extends CharacterBody2D
# TODO:
# 4 - Fazer o STOMP ser habilidade coletável
# 8 - Fazer com que o inventário possa dar split nos itens
# 9 - Fazer com que os itens coletados no jogo apareçam no Inventário
# 10 (Opcional) - Adicionar animações (Tweening) no itens

# Faz com que o AnimatedSprite2D esteja sempre pronto para uso em qualquer parte do código
# Isso evita com que a animação não seja carregada
@onready var anim: AnimatedSprite2D = $anim

var speed := 150.0

const jump_speed = -300.0
const jump_cutoff = 0.5

# Estabelece o número máximo de Pulos Máximos do jogador
# De início, o número de pulos máximos é 1
var maxJumps := 1

var isStomping := false
var isJumping := false
var isDashing := false

# Verifica se o jogador possui os poderes abaixo:
var dash := false
var doubleJump := false
var tearDown := false
## Time Warp
var timeWarp := false

var timeFactor := 0.5 # Fator padrão de tempo (Metade do tempo)
var timeWarpActivated := false

## Recarga das Habilidades:
var twReloading := false
var dashReloading := false
var stompReloading := false

# Delay antes do Stomp e Carga do mesmo:
var preStomp := false
var stompCharge := 0.0

var dashSpeed := 450.0 # Velocidade do DASH
var dashDuration := 0.5 # Duração do DASH

# Verifica se o jogador está totalmente parado
var idle := false

# Processo executado a CADA FRAME possível do jogo
func _physics_process(delta: float) -> void:
	
	# Adiciona a gravidade - Padrão: 980.0 px/s
	if not is_on_floor() and not isDashing and not preStomp:
		velocity += get_gravity() * delta # Velocidade de gravidade do projeto (Padrão) * Frames possíveis
	
	if not is_on_floor() and isDashing or preStomp:
		velocity.y = 0 # Zera a velocidade Y do jogador
	
	if preStomp:
		velocity.x = 0
	elif !preStomp and isStomping:
		velocity.y += 300 * stompCharge/10
	
	if is_on_floor():
		velocity.y = 0
		isJumping = false
		isStomping = false
		stompCharge = 0
	
	if anim.animation != "idle" and velocity.x == 0 and !preStomp:
		anim.play("idle")
	
	if is_on_floor() and doubleJump == true:
		maxJumps = 2 # Pulos máximos = 2 (Apenas para verificação)
	
	# Tecla L pressionada ativa o Time Warp
	if Input.is_action_just_pressed("time_warp") and timeWarp and !twReloading and !timeWarpActivated:
		await slow_motion()

	# Verifica a tecla de pulo
	if Input.is_action_pressed("jump") and is_on_floor():
		isJumping = true # Atualiza o verificador de pulo
		velocity.y = jump_speed # Utiliza velocidade para não "teleportar" o jogador para cima

	# Permite o Pulo Duplo, se liberado
	if Input.is_action_just_pressed("jump") and not is_on_floor() and not isDashing and maxJumps > 1:
		isJumping = true
		velocity.y = jump_speed * 0.9 # Indica que o segundo pulo será menor
		maxJumps = 0 # Zera o contador de pulos máximos para garantir que o jogador não irá sair voando

	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= jump_cutoff  # Reduz a velocidade do pulo
	
	# Detecta a ação de STOMPAR
	if Input.is_action_pressed("crouch") and Input.is_action_pressed("use_power") and tearDown and !isDashing and !is_on_floor() and !stompReloading:
		if stompCharge <= 5.0:
			stompCharge += 0.1
		preStomp = true
		print(stompCharge)
	if (Input.is_action_just_released("use_power") or stompCharge >= 5.0) and preStomp:
		isStomping = true
		stompReloading = true
		preStomp = false
		print("tometomeome")
		$timers/stompCooldown.start()
		
	# Detecta a ação de DASH
	if (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")) and Input.is_action_just_pressed("use_power") and dash and not dashReloading and not isStomping:
		isDashing = true
		dashReloading = true
		$timers/dashTimer.start() # Duração do DASH: 0.25 segundos
		$timers/dashCooldown.start() # Recarga de 2 segundos
		
		var direction = Input.get_axis("move_left", "move_right")
		velocity.x = direction * dashSpeed
		
	if Input.is_action_just_pressed("downdown"):
		downdown()
	dev_tool()
	player_movement()
	move_and_slide()

func player_movement():
	
	
	# Pega o INPUT da direção do jogador e com isso, o movimenta pelo cenário
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction and !isStomping:
		if !timeWarpActivated:
			idle = false
			velocity.x = direction * speed
		else:
			idle = false
			velocity.x = direction * speed * 2
	
	elif velocity.y != 0:
		idle = false
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		idle = true
		

	# Detecta movimentação para mudar o sprite
	if not idle:
		if preStomp:
			anim.play("charging_stomp")
			return
		
		if not timeWarpActivated and not isDashing and not isJumping:
			if direction > 0:
				anim.flip_h = false # Olhando para a direita
				anim.play("moving") # Toca a animação de Mover
			elif direction < 0:
				anim.flip_h = true # Olhando para a esquerda
				anim.play("moving") # Toca a animação de Mover, porém espelhada
		
		elif timeWarpActivated and not isJumping and not isDashing:
			if direction > 0:
				anim.flip_h = false # Olhando para a direita
				anim.play("running") # Toca a animação de Correr
			elif direction < 0:
				anim.flip_h = true # Olhando para a esquerda
				anim.play("running") # Toca a animação de Correr, porém espelhada
			
		elif isJumping and not isDashing and !(preStomp or isStomping):
			if direction > 0:
				anim.flip_h = false # Olhando para a direita
			elif direction < 0:
				anim.flip_h = true # Olhando para a esquerda
			
			anim.play("jump") # Personagem Pulando
		
		elif isJumping and (isStomping or preStomp):
			anim.play("charging_stomp")
			
		else:
			if direction > 0:
				anim.flip_h = false # Olhando para a direita
				anim.play("dash_midair") # Personagem Dashando
			elif direction < 0:
				anim.flip_h = true # Olhando para a esquerda
				anim.play("dash_midair") # Personagem Dashando

	
	anim.speed_scale = direction * 1.5

func slow_motion(duration: float = 5):
	timeWarpActivated = true
	print("Time Warp")
	Engine.time_scale = timeFactor # Determina a escala de tempo da Engine, isso inclui TODOS os nós
	await get_tree().create_timer(duration/2, false, false, true).timeout # Cria um timer assíncrono que não será processado sempre, afetado por Física, e nem pelo Time Factor do jogo, respectivamente
	print("Time Warp Acabou")
	timeWarpActivated = false
	twReloading = true
	Engine.time_scale = 1.0
	
	if twReloading == true:
		print("Recarregando...")
		await get_tree().create_timer(1, false, false, true).timeout
		twReloading = false
		print("Recarregado!")

func dev_tool():
	# DEV_TOOL = HOME no teclado; Libera todo tipo de mecânica possível
	if Input.is_action_just_pressed("DEV_TOOL"):
		doubleJump = true # Libera TODOS OS PODERES! (DEV TOOL)
		timeWarp = true
		tearDown = true
		dash = true
		print("Double Jump; Time Warp; Tear Down; Dash desbloqueado!")
		
		print("- Double Jump = Pule no AR!")
		print("- Time Warp = Pressione L para diminuir o FLUXO TEMPORAL")
		print("- Tear Down = Dê um ataque DESCENDENTE e ESMAGADOR!")
		print("- Lightspeed = AVANCE na velocidade da LUZ!")
		
func downdown():
	print("Testando o DOWNDOWN...")
	print("PreStomp: " + str(preStomp))
	print("isStomping: " + str(isStomping))
	print("Stomp Charge: " + str(stompCharge))


func _on_dash_timer_timeout() -> void:
	isDashing = false # Replace with function body.
	velocity.x = 0

func _on_dash_cooldown_timeout() -> void:
	dashReloading = false # Replace with function body.

func _on_stomp_cooldown_timeout() -> void:
	stompReloading = false # Replace with function body.
