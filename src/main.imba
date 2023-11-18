global css
	* e:300ms box-sizing:border-box
	body c:warm2 bg:warm8 ff:Arial inset:0 d:vtl p:0 m:0
	button bg:none ol:none c:white px:8px py:5px rd:2
		bd:none
		@hover bg:green3/50
	.buttons d:hcc g:1

extend class Array
	get sum
		reduce(&,0) do(acc, cur) $1 + $2

tag app

	setup-duration = 3s

	state = imba.locals.state or """
	# Sitting
	Hurdle Right 1m
	Hurdle Left 1m
	Butterfly 1m
	Half Lotus Right 1m
	Half Lotus Left 1m
	IT Band Right 1m
	IT Band Left 1m
	Calf Right 1m
	Calf Left 1m

	# Seiza
	Thumb + Toes 15s
	Hand Curl + Toes Right 7s
	Hand Curl + Toes Left 7s

	# Wall
	Splits 3m

	# Door Frame
	# Shoulder level then high twist
	Lats Right 45s
	Lats Left 35s

	# Wall
	Delts Right 45s
	Delts Left 35s
	Chest Right 25s
	Chest Left 25s
	# Push hand with your other hand away from your body
	Triceps Right 30s
	Triceps Left 30s
	Hand + Calf Right Setup 5s
	Thumb 7s
	Index 7s
	Middle 7s
	Ring 7s
	Pinkie 7s
	Hand + Calf Left Setup 5s
	Thumb 7s
	Index 7s
	Middle 7s
	Ring 7s
	Pinkie 7s

	# Standing
	Towel Over Head 40s
	Thumb Out Neck Right 20s
	Thumb Out Neck Left 10s
	Tricep + Bend Right 20s
	Tricep + Bend Left 20s
	Beached Whale + Child's Pose 10m

	# Hanging Back Stretch 1m
	"""

	get data
		state.split("\n").filter(do $1 and !$1.startsWith('#'))

	get total-duration
		let arr = (get-duration(line) for line in data)
		arr.sum / 1000 / 60

	get elapsed
		(Date.now! - started) / 1000

	get duration
		if setting-up?
			setup-duration / 1000
		else
			get-duration(data[index]) / 1000

	get remaining
		(duration - elapsed).toFixed(2)

	def get-duration text
		let last = text.split(" ")[-1]
		if last.endsWith 'm'
			parseInt(last.substring(0,last.length - 1)) * 60 * 1000
		else
			parseInt(last.substring(0,last.length - 1)) * 1000

	get display-current
		if setting-up?
			"Setup"
		else
			current.substring(0,current.lastIndexOf(" "))

	def speak text
		text = text
			.replace(/m$/, ' minute')
			.replace(/s$/, ' second')
			.replace(/(?= \w+ \w+$)/, ',')
		unless /\ 1 \w+$/.test(text) then text += 's'
		global.speechSynthesis.cancel!
		global.speechSynthesis.speak(new SpeechSynthesisUtterance(text))

	def save
		imba.locals.state = state
		editing? = no

	def stop
		index = 0
		started = no
		current = no
		setting-up? = no

	def play i
		index = i

		setting-up? = yes
		started = Date.now!
		timer = new Promise do(resolve, reject)
			timeout = setTimeout(resolve,setup-duration)
			cancel = do
				clearTimeout timeout
				reject!
		try
			await timer
		catch
			return stop!
		setting-up? = no

		while index < data.length
			started = Date.now!

			current = data[index]
			imba.commit!

			speak(current)

			timer = new Promise do(resolve, reject)
				next = resolve
				prev = do
					index = Math.max(-1, index - 2)
					resolve!
				again = do
					index = Math.max(-1, index - 1)
					resolve!
				cancel = do
					clearTimeout timeout
					reject!
				timeout = setTimeout(next,get-duration(data[index]))

			try
				await timer
			catch
				break

			index += 1

		stop!

	<self autorender=10ms>
		css d:vcc s:100%

		<%top>
			css d:vcc w:100% h:500px g:10px

			if started

				if setting-up?
					<.buttons>
						<button @click=cancel> "CANCEL"
				else
					<.buttons>
						<button @click=cancel> "CANCEL"
						<button @click=next> "NEXT"
						<button @click=prev> "PREV"
						<button @click=again> "AGAIN"

				<%current>
					css fs:100px
					display-current

				<%timer>
					css fs:80px
					started ? remaining : 0

			else
				<.buttons>
					<button @click=play(0)> "PLAY"
					if editing?
						<button @click=save> "SAVE"
					else
						<button @click=(editing? = yes)> "EDIT"

				<%total>
					css d:hcc ws:pre
					<div> total-duration
					<div> " minutes"

				if editing?
					<textarea bind=state>
						css s:500px

				else
					<%container>
						css p:15px bd:1px solid blue4 rd:4 h:200px of:auto

						<%lines>
							css d:vcl g:10px

							for line, i in data
								<%line @click=play(i)> line
									css cursor:default w:100%
										@hover c:blue4
									if current is line
										css
											@important c:green3

imba.mount <app>
