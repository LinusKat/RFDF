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
		Timestamp = 1769036400,
		Name = "v2",
		Data = {
			{
				Info = "Hello [asdh2y9as]",
				Author = "LinusKat",
				Date = "1-1-2026",
			}:: Change,
			{
				Info = "World [2d2f]",
				Author = "LinusKat",
				Date = "1-1-2026",
			}:: Change,
			{
				Info = "Hello [245]",
				Author = "LinusKat",
				Date = "1-1-2026",
			}:: Change,
			{
				Info = "World [f3f]",
				Author = "LinusKat",
				Date = "1-1-2026",
			}:: Change,
			{
				Info = "Hello [94ui]",
				Author = "LinusKat",
				Date = "1-1-2026",
			}:: Change,
		},
	}:: Version,
	
	{
		Timestamp = 1769036400,
		Name = "v1",
		Data = {
			{
				Info = "Hello [asdh2y9as]",
				Author = "LinusKat",
				Date = "1-1-2026",
			}:: Change,
			{
				Info = "World [2d2f]",
				Author = "LinusKat",
				Date = "1-1-2026",
			}:: Change,
			{
				Info = "Hello [245]",
				Author = "LinusKat",
				Date = "1-1-2026",
			}:: Change,
			{
				Info = "World [f3f]",
				Author = "LinusKat",
				Date = "1-1-2026",
			}:: Change,
			{
				Info = "Hello [94ui]",
				Author = "LinusKat",
				Date = "1-1-2026",
			}:: Change,
		},
	}:: Version,
}