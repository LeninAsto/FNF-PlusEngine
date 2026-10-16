State = State or {}
Substate = Substate or {}
Input = Input or {}

function State.sprite(tag, image, x, y, camera)
	makeLuaSprite(tag, image, x or 0, y or 0)
	if camera ~= nil then
		setObjectCamera(tag, camera)
	end
	addLuaSprite(tag, true)
	return tag
end

function State.text(tag, text, x, y, width, alignment, camera)
	makeLuaText(tag, text or '', width or screenWidth, x or 0, y or 0)
	if alignment ~= nil then
		setTextAlignment(tag, alignment)
	end
	if camera ~= nil then
		setObjectCamera(tag, camera)
	end
	addLuaText(tag)
	return tag
end

function State.centerX(tag)
	local width = getProperty(tag .. '.width') or 0
	setProperty(tag .. '.x', (screenWidth - width) * 0.5)
end

function State.centerY(tag)
	local height = getProperty(tag .. '.height') or 0
	setProperty(tag .. '.y', (screenHeight - height) * 0.5)
end

function Substate.close()
	return closeLuaSubstate()
end

function Substate.callParent(name, ...)
	return callStateFunction(name, {...})
end

function Input.accept()
	return keyboardJustPressed('ENTER') or keyboardJustPressed('SPACE')
end

function Input.back()
	return keyboardJustPressed('ESCAPE') or keyboardJustPressed('BACKSPACE')
end
