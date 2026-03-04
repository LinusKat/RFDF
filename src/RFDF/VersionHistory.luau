export type Change = {
	Info: string,
	Author: string,
	Date: string,
}
export type Version = {
	Timestamp: number,
	Name: string,
	Data: {Change},
}

return {
	{
		Timestamp = 1772499000,
		Name = "v-0.0.0 internal release",
		Data = {
			{
				Info = "Initial Release (Endpoint DDoS Protections not implemented yet will be in a future release)",
				Author = "LinusKat",
				Date = "3-3-2026",
			}:: Change,
		},
	}:: Version,
}