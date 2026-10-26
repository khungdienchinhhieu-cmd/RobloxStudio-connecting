--!strict
--[[
	CullMath.luau — phép toán thuần cho CityCuller (không dùng Instance, dễ kiểm thử).

	Vì sao cần: trước đây mỗi ô đất (một Folder rộng ~184×144 stud) chỉ có MỘT điểm đại diện,
	là trung bình của 24 part đầu tiên, không phải tâm ô. Khi điểm đó ra khỏi khung hình hoặc
	xa hơn 900 stud, cả ô bị cất đi, nên nhà "mất tiêu rồi hiện lại".

	Thay bằng:
	  • Khoảng cách tới CẠNH hộp bao của ô (không phải tới một điểm).
	  • Kiểm tra khung hình bằng 8 góc hộp bao (chỉ cần một góc nhìn thấy là giữ).
	  • Trễ khi cất: phải "ngoài tầm" liên tiếp nhiều nhịp mới cất, để không chớp khi quay camera.
]]

local CullMath = {}

--- Khoảng cách trên mặt phẳng XZ từ điểm (px,pz) tới hình chữ nhật [minX..maxX]×[minZ..maxZ].
--- Điểm nằm trong hình chữ nhật → 0.
function CullMath.distToBoxXZ(px: number, pz: number, minX: number, minZ: number, maxX: number, maxZ: number): number
	local dx = math.max(minX - px, 0, px - maxX)
	local dz = math.max(minZ - pz, 0, pz - maxZ)
	return math.sqrt(dx * dx + dz * dz)
end

--- Quyết định GIỮ (true) hay CẤT (false) một khối.
---   dist          : khoảng cách từ người chơi tới cạnh khối (XZ)
---   anyOnScreen   : có góc nào của hộp bao nằm trong khung hình không
---   prevVisible   : trạng thái hiện tại (dùng trong dải trễ)
function CullMath.decide(
	dist: number,
	anyOnScreen: boolean,
	prevVisible: boolean,
	nearR: number,
	farR: number,
	behindR: number,
	hyst: number
): boolean
	if dist <= nearR - hyst then
		return true
	end
	if dist >= farR + hyst then
		return false
	end
	if dist > behindR then
		return anyOnScreen
	end
	return prevVisible
end

--- Trễ khi cất: trả về (cấtNgay, offTicksMới).
--- Chỉ cất khi quyết định "không giữ" đã lặp lại đủ `need` nhịp liên tiếp.
--- Giữ thì luôn reset bộ đếm và không cất.
function CullMath.hideDebounce(keep: boolean, offTicks: number, need: number): (boolean, number)
	if keep then
		return false, 0
	end
	local n = offTicks + 1
	return n >= need, n
end

--- Tám góc hộp bao, trả về mảng {x,y,z} (y không dùng cho kiểm khung hình nhưng giữ để đầy đủ).
function CullMath.corners(minX: number, minY: number, minZ: number, maxX: number, maxY: number, maxZ: number): { { number } }
	local out = {}
	for _, x in ipairs({ minX, maxX }) do
		for _, y in ipairs({ minY, maxY }) do
			for _, z in ipairs({ minZ, maxZ }) do
				table.insert(out, { x, y, z })
			end
		end
	end
	return out
end

return CullMath
