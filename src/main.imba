global css
	* e:300ms box-sizing:border-box
	body c:warm2 bg:gray9 ff:Arial inset:0 d:vtl p:0 m:0
	button bg:clear ol:none c:white px:8px py:5px rd:2
		bd:none
		@hover bg:blue4/70
	.buttons d:hcc g:1

extend class Array
	get sum
		reduce(&,0) do(acc, cur) $1 + $2
	get has
		includes

extend class String
	get has
		includes

tag app

	setup-duration = 1ms

	@observable state = imba.locals.state or """
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
	Hand + Calf Right Setup 7s
	Thumb 7s # nospeaktime
	Index 7s # nospeaktime
	Middle 7s # nospeaktime
	Ring 7s # nospeaktime
	Pinkie 7s # nospeaktime
	Hand + Calf Left Setup 7s
	Thumb 7s # nospeaktime
	Index 7s # nospeaktime
	Middle 7s # nospeaktime
	Ring 7s # nospeaktime
	Pinkie 7s # nospeaktime

	# Standing
	Towel Over Head 40s
	Thumb Out Neck Right 20s
	Thumb Out Neck Left 10s
	Tricep + Bend Right 20s
	Tricep + Bend Left 20s
	# Hanging Back Stretch 1m
	Beached Whale + Child's Pose 10s
	"""

	@computed get data
		let out = []
		let all = state.split("\n")
		for line in all
			continue unless line
			continue if line.startsWith '#'

			let data = {}
			let opts
			[line, opts] = line.split(/\s*#\s*/)

			if opts
				for opt in opts..split(/\s+/)
					data[opt] = yes

			line = line.split(/\s+/)
			data.duration = line.pop!
			data.text = line.join(' ')

			out.push data
		out

	get total-duration
		let arr = (get-duration(o.duration) for o in data)
		parseInt arr.sum / 1000 / 60

	get elapsed
		(Date.now! - started) / 1000

	get duration
		if setting-up?
			setup-duration / 1000
		else
			get-duration(current.duration) / 1000

	get remaining
		parseInt(duration - elapsed)

	def get-duration text
		if text.endsWith 'm'
			parseInt(text.substring(0,text.length - 1)) * 60 * 1000
		else
			parseInt(text.substring(0,text.length - 1)) * 1000

	get display-current
		if setting-up?
			"Setup"
		else
			current.text

	def speak text, o
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

			let tospeak = (current.text + ' ' + current.duration)
				.replace(/m$/, ' minute')
				.replace(/s$/, ' second')
				.replace(/(?= \w+ \w+$)/, ',')
			unless /\ 1 \w+$/.test(tospeak) then tospeak += 's'
			if current.nospeaktime
				tospeak = current.text

			speak(tospeak)

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
				timeout = setTimeout(next,get-duration(current.duration))

			try
				await timer
			catch e
				console.error e
				break

			index += 1

		stop!

	<self autorender=100ms>
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
						<button @hotkey('right') @click=next> "NEXT"
						<button @click=prev> "PREV"
						<button @click=again> "AGAIN"

				<%current>
					css fs:100px ta:center
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
						css s:500px bg:clear c:warm2 p:3 rd:3 ol:none bd:1px dashed blue4

				else
					<%container>
						css bd:1px solid blue4 rd:4 s:500px of:auto

						<%lines>
							css d:vcl

							for o, i in data
								<%line @click=play(i)> o.text
									css cursor:default w:100% px:15px py:10px
										@hover bg:white/10
									if o is current
										css
											@important c:green3

imba.mount <app>
