module.exports = {
	pollFrequency: 100
	sensorUnit: 'farenheight'
	sensors: [
		{
			name: 'ambient',
			id: '000004bcb49a',
			control: "none"
		},
		{
			name: 'fermenter_1',
			id: '000004bd452f',
			gpio: 7,
			control: "manual",
			sv: "70"
		},
		{
			name: 'fermenter_2',
			id: '000004bd9529',
			gpio: 8,
			control: "pid",
			sv: "70"
		}
	]
}