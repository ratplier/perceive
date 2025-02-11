--!nonstrict
local RunService = game:GetService("RunService")

local config = {
	enabled = true,
	color = Color3.new(1, 1, 1),
	alwaysOnTop = true,
	vectorRadius = 0.1,
	pointRadius = 0.1,
	lineRadius = 0.02,
	lineInnerRadius = 0,
	transparency = 0.5,
	cframeLength = 1,
	cacheAdornments = true,
	vectorLine = false
}

type Swappable<T> = {
	used: { T },
	unused: { T },
}
type HandleAdorments = "ConeHandleAdornment" | "CylinderHandleAdornment" | "SphereHandleAdornment"
export type config = {
	enabled: boolean,
	color: Color3,
	alwaysOnTop: boolean,
	transparency: number,
	cframeLength: number,
	vectorRadius: number,
	vectorLine: boolean,
	pointRadius: number,

	lineRadius: number,
	lineInnerRadius: number,

	cacheAdornments: boolean,
}
export type Perceiver = {
	configure: typeof(
		-- Override the default Visualizer settings.
		function(settings: config) end
	),
	vector: typeof(
		-- Render a direction
		-- --------------------------------------------------------------
		-- origin The origin of the vector.
		-- direction The direction of the vector.
		-- color An optional color.
		function(origin: Vector3, direction: Vector3, color: Color3?) end
	),
	point: typeof(
		-- Render a single position as a point
		-- --------------------------------------------------------------
		-- origin The point's location.
		-- color An optional color.
		function(origin: Vector3, color: Color3?) end
	),
	line: typeof(
		-- Draw a line between two points
		-- --------------------------------------------------------------
		-- start The start of the line.
		-- finish The end of the line.
		-- color An optional color.
		function(start: Vector3, finish: Vector3, color: Color3?) end
	),
	cframe: typeof(
		-- Render a CFrame.
		-- --------------------------------------------------------------
		-- Equivalent to: Visualize.vector(pos, lookVector, color)
		-- cframe The CFrame to render.
		-- color An optional color.
		function(cframe: CFrame, color: Color3?) end
	),
}

local function wrap<S, B..., R...>(self: S)
	return function(fn: (S, B...) -> (R...))
		return function(...:B...): R...
			return fn(self, ...)
		end
	end
end

local function createHandleAdorment(self, className: HandleAdorments): HandleAdornment
	local instance = Instance.new(className)
	instance.Transparency = config.transparency
	instance.AlwaysOnTop = config.alwaysOnTop
	instance.Color3 = config.color
	instance.Visible = true
	instance.ZIndex = 2
	instance.Adornee = workspace.Terrain
	instance.Parent = workspace.Terrain
	return instance
end

local function createSwappable<T>(self): Swappable<T>
	local swappable = {
		used = {},
		unused = {}
	}
	table.insert(self.swappables, swappable)
	return swappable
end

local function pop<T>(self, swappable: Swappable<T>)
	if self.config.cacheAdornments then
		return table.remove(self.swappable.unused)
	end
end

local function step(self)
	for _, swappable in self.swappables do
		for _,unused in swappable.unused do
			unused:Destroy()
		end
		self.swappable.unused = swappable.used
		self.swappable.used = {}
	end
end

local function configure(self, settings: config)
	for property, option in settings do
		self.config[property] = option
	end
end

local function vector(self, origin: Vector3, direction: Vector3, color: Color3?)
	if not self.config.enabled then return end
	
	color = if typeof(color) ~= "Color3" then self.config.color else color
	
	local adornment = self.pop(self.vectors)
	if not adornment then
		local adormentType = if self.config.vectorLine then "CylinderHandleAdornment" else "ConeHandleAdornment"
		adornment = self.createHandleAdornment(adormentType)
	end
	
	local offset = if self.config.vectorLine then direction.Magnitude / 2 else 0
	adornment.Height = math.max(direction.Magnitude, 1)
	adornment.Radius = self.config.vectorRadius
	
	adornment.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.new(0, 0, -offset)
	adornment.Color3 = color
	
	table.insert(self.vectors.used, adornment)
end

local function point(self, origin: Vector3, color: Color3?)
	if not self.config.enabled then return end

	color = if typeof(color) ~= "Color3" then self.config.color else color

	local adornment = self.pop(self.points)
	if not adornment then
		adornment = self.createHandleAdornment("SphereHandleAdornment")
	end
	
	adornment.Radius = self.config.pointRadius
	
	adornment.CFrame = CFrame.new(origin)
	adornment.Color3 = color
	
	table.insert(self.points.used, adornment)
end

local function line(self, start: Vector3, finish: Vector3, color: Color3?)
	if not self.config.enabled then return end

	color = if typeof(color) ~= "Color3" then self.config.color else color

	local adornment = self.pop(self.points)
	if not adornment then
		adornment = self.createHandleAdornment("SphereHandleAdornment")
	end
	
	local length = (start - finish).Magnitude
	
	adornment.Height = length
	adornment.Radius = self.config.lineRadius
	adornment.InnerRadius = self.config.lineInnerRadius
	
	adornment.CFrame = CFrame.lookAt(start, finish) * CFrame.new(0, 0, -length/2)
	adornment.Color3 = color

	table.insert(self.lines.used, adornment)
end

local function cframe(self, cframe: CFrame, color: Color3?)
	self.vector(cframe.Position, cframe.LookVector * self.config.cframeLength, color)
end

local function perceiver(settings: config): Perceiver
	local self = {}
	
	self.pop = wrap(self)(pop)
	self.step = wrap(self)(step)
	self.createSwappable = wrap(self)(createSwappable)
	self.configure = wrap(self)(configure)
	self.createHandleAdornment = wrap(self)(createHandleAdorment)
	
	self.vector = wrap(self)(vector)
	self.point = wrap(self)(point)
	self.line = wrap(self)(line)
	self.cframe = wrap(self)(cframe)
	
	self.config = table.clone(config)
	
	self.swappable = {}
	self.vectors = self.createSwappable() :: Swappable<ConeHandleAdornment | CylinderHandleAdornment>
	self.points = self.createSwappable() :: Swappable<SphereHandleAdornment>
	self.lines = self.createSwappable() :: Swappable<CylinderHandleAdornment>
	
	if settings then self.configure(settings) end
	
	if RunService:IsServer() then
		RunService.Heartbeat:Connect(self.step)
	elseif RunService:IsClient() then
		RunService.RenderStepped:Connect(self.step)
	end
	
	return self
end

return {
	perceiver = perceiver,
	perceive = perceiver(config),
}