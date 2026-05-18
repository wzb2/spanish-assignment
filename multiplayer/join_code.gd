extends Object

class_name JoinCode

const LETTERS: String = "ABCDEFGHIJ"
const PERIOD_CHAR: String = "K"
const SEPERATOR_CHAR: String = "L"

static func _convert_num_to_letters(text: String) -> String:
	var letterified_text: String = ""
	
	for c in text:
		if not c == ".":
			letterified_text += LETTERS[int(c)]
		else:
			letterified_text += PERIOD_CHAR
	
	return letterified_text

static func _convert_letters_to_numbers(text: String) -> String:
	var numberified_text: String = ""
	
	for c in text:
		if not c == PERIOD_CHAR:
			numberified_text += str(LETTERS.find(c))
		else:
			numberified_text += "."
			
	return numberified_text


static func encode(ip: String, port: int) -> String:
	return _convert_num_to_letters(ip) + SEPERATOR_CHAR + _convert_num_to_letters(str(port))


static func decode_ip(code: String) -> String:
	return _convert_letters_to_numbers(code.split(SEPERATOR_CHAR)[0])
	

static func decode_port(code: String) -> int:
	return int(_convert_letters_to_numbers(code.split(SEPERATOR_CHAR)[1]))


static func is_code_valid(code: String) -> bool:
	if not code:
		return false
	
	var port: int = decode_port(code)
	var split_code: PackedStringArray = code.split(SEPERATOR_CHAR)
	
	return is_valid_ipv4(decode_ip(code)) and len(split_code) == 2 and code.contains(PERIOD_CHAR) and port == clamp(port, 1, 65535)

static func is_valid_ipv4(ip: String) -> bool:
	var octets: PackedStringArray = ip.split(".")
	
	var valid_octets: bool = true
	
	if len(octets) != 4:
		valid_octets = false
	else:
		for i in octets:
			var numbers: int = int(i)
			if not i.is_valid_int() or numbers != clamp(numbers, 0, 255) or (len(i) > 1 and i[0] == "0"):
				valid_octets = false
	return valid_octets
