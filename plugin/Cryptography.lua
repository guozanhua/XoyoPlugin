Include("aeslua");

local szPassword = "linbinbin shi ge huai dan";

function Encryption(str)
	return aeslua.encrypt(szPassword, str);
end

function Decryption(str)
	return aeslua.decrypt(szPassword, str);
end