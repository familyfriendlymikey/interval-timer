global css
	* box-sizing:border-box c:$text-c
	body m:0 bd:0 p:0 bg:#20222f
	.dark
		$appbg:#20222f
		$bodybg:#20222f
		$selected-c:blue3/5
		$bang-c:#fad4ab
		$text-c:blue3
		$input-bg:purple4/5
		$input-c:blue3
		$input-caret-c:blue3
		$input-bc:purple4
		$tip-hotkey-c:purple3/50
		$tip-content-c:purple3
		$tip-hover-c:purple3/3
		$tip-bc:blue3/10
		$button-c:purple3/90
		$button-dim-c:purple3/50
		$button-bg:purple4/10
		$button-hover-bg:purple4/20
	button
		bg:clear bd:none fs:14px d:hcc fl:1 rd:5px
		transition:background 100ms
		h:100% px:5px
		of:hidden text-overflow:ellipsis white-space:nowrap
		bg:$button-bg c:$button-c
		@hover bg:$button-hover-bg
	.buttons
		d:hcc w:100% h:50px mt:10px g:10px flex:none

extend class Array
	get sum
		reduce(&,0) do(acc, cur) $1 + $2
	get has
		includes

extend class String
	get has
		includes

tag app

	setup-duration = 3s

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
		setTimeout(&,100ms) do global.speechSynthesis.speak(new SpeechSynthesisUtterance(text))

	def cancel-edit
		editing? = no

	def save-edit
		state = newstate
		imba.locals.state = state
		editing? = no

	def edit
		newstate = state
		editing? = yes

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

	<self.dark autorender=100ms>
		css d:flex fld:column jc:start ai:center
			m:0 w:100% h:100% bg:$bodybg
			ff:sans-serif fw:1
			us:none
			e:100ms
			@off o:0

		<%main>
			css d:flex fld:column jc:start ai:center
				bg:$appbg
				w:80vw max-width:700px mah:80vh
				bxs:0px 0px 10px rgba(0,0,0,0.35)
				box-sizing:border-box p:30px rd:10px mt:10vh
				w:100% d:flex fld:column ofy:hidden gap:20px

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
					css fs:100px ta:center fl:1 d:vcc
					display-current

					<%timer>
						css fs:80px
						started ? remaining : 0

			else
				<.buttons>
					if editing?
						<button @click=cancel-edit> "CANCEL"
						<button @click=save-edit> "SAVE"
					else
						<button @click=play(0)> "PLAY"
						<button @click=edit> "EDIT"

				<%total>
					css c:$tip-content-c
					"{data.len} intervals, {total-duration} minutes total"

				if editing?
					<textarea bind=newstate rows=1000>
						css bg:clear p:3 rd:3 ol:none bd:1px dashed $input-bc s:100% bg:$input-bg resize:none

				else
					<%container>
						css w:100% d:flex fld:column gap:15px ofy:hidden max-height:100%

						<div>
							css ofy:auto

							for o, i in data
								<%line @click=play(i)>
									css d:flex fld:row jc:space-between ai:center
										px:16px py:11px rd:5px c:$text-c
										@hover bg:$selected-c

									<%left> o.text
									<%right> o.duration

imba.mount <app>
