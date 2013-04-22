module.exports = {
	pollFrequency: 100
	sensorUnit: 'farenheight'
	sensors: [
		{
			name: 'ambient',
			id: '000004bd611f',
			control: "none"
		},
		{
			name: 'fermenter_1',
			id: '000004bcb49a',
			gpio: 25,
			control: "manual",
			sv: "70"
		},
		{
			name: 'fermenter_2',
			id: '000004bd0d7b',
			gpio: 8,
			control: "pid",
			sv: "70"
		}
	]
}