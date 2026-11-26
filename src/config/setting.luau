export type Identity<T> = {
	description: string,
	default: T,
	parse: (text: string) -> T,
}

return nil
