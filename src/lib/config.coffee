module.exports = {
	pollFrequency: 1000
	sensorUnit: 'farenheight'
	sensors: [
		{
			name: 'ambient'
			label: 'Ambient'
			id: '000004bd611f'
			type: 'ambient'
		},
		{
			name: 'fermenter_1'
			label: 'Fermenter #1'
			id: '000004bcb49a'
			type: 'fermenter'
			gpio: 25
		},
		{
			name: 'fermenter_2'
			label: 'Fermenter #2'
			id: '000004bd0d7b'
			type: 'fermenter'
			gpio: 8
		}
	]
}