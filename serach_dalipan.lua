local curl = require "lcurl.safe"
local cookie = ""
local referer_url = ""

script_info = {
	["title"] = "大力盘",
	["description"] = "https://www.dalipan.com/",
	["version"] = "0.0.2",
}

function request(url,header)
	local r = ""
	local c = curl.easy{
		url = url,
		httpheader = header,
		ssl_verifyhost = 0,
		ssl_verifypeer = 0,
		followlocation = 1,
		timeout = 15,
		proxy = pd.getProxy(),
		writefunction = function(buffer)
			r = r .. buffer
			return #buffer
		end,
	}
	local _, e = c:perform()
	c:close()
	return r
end



function onSearch(key, page)

	local header = {
			"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36",
		}
		
	local data = request("https://www.dalipan.com/search?keyword=" .. pd.urlEncode(key) .. "&page=" .. page, header)
	local result = {}
	local start = 1
	local ctime= os.time()	
	local _,_,ck = string.find(data, "https://hm.baidu.com/hm.js??(.-)\"")
	if ck then
		cookie = "Hm_lvt_" .. ck .. "=".. ctime .. "; Hm_lpvt_" .. ck  .. "="..(ctime+15)
	end
	referer_url = "https://www.dalipan.com/search?keyword=" .. pd.urlEncode(key) .. "&page=" .. page
	
	while true do
	
		local a, b, img, id, title, time = string.find(data, '<div class="resource%-item"><img src="(.-)".-<a href="/detail/(.-)" target="_blank" class="valid">(.-)</a>.-<p class="time">(.-)</p>', start)
			
		if id == nil then
			break
		end
			
		--title = string.gsub(title, "^%s*", "", 1)
		local tooltip = string.gsub(title, "<mark>(.-)</mark>", "%1")
		title = string.gsub(title, "<mark>(.-)</mark>", "{c #ff0000}%1{/c}")
		table.insert(result, {["id"] = id , ["title"] = title,  ["showhtml"] = "true", ["tooltip"] = tooltip, ["time"] = time, ["image"] = "https://dalipan.com" .. img, ["icon_size"] = "35,40"})
		-- table.insert(result, {["url"] = url .. " " .. pwd, ["title"] = title,  ["showhtml"] = "true", ["tooltip"] = tooltip, ["check_url"] = "true", ["time"] = time})
		start = b + 1
		
	end
	return result
end


function parseDetail(item)

		header = {
			"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36",
			"referer: " .. referer_url,
			"cookie: " .. cookie,
		}
		--local image_url = "https://www.dalipan.com/images/recommand.png"
		local deatil_url = "https://www.dalipan.com/detail/".. item.id
		local ret = request(deatil_url, header)
		local _,_,url = string.find(ret, "<a target=\"_blank\" href=\"(.-)\"")
		local _,_,pwd = string.find(ret,">提取密码</span>(.-)<span")
		if pwd == nil then
			return url
		else
			pwd = string.gsub(pwd, "\r","")
			pwd = string.gsub(pwd, "\n","")
			pwd = string.gsub(pwd," ", "")
			return url .. " " .. pwd
		end
end

function onItemClick(item)

	local url = parseDetail(item)
	if url == nil then
		return ACT_MESSAGE, '获取URL失败'
	end
	return ACT_SHARELINK, url 
end

