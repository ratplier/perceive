# perceive

`perceive` is a module that allows you to visualize data in 3D space

## Example usage
```luau
local RunService = game:GetService("RunService")
local perceive = require(path.to.perceive)

local perceiver = perceive.visualizer({
    alwaysOnTop = false
})

RunService.RenderStepped:Connect(function()
    -- Default color point
    perceiver.point(Vector3.new(0, 5, 0))

    -- Blue Line
    perceiver.line(Vector3.new(0, 5, 0), Vector3.new(0, 2.5, 0), Color3.new(0, 0, 1))
    
    -- Green cframe
    perceiver.cframe(workspace.CurrentCamera.CFrame, Color3.new(0, 1, 0))

    -- Pink vector
    perceiver.vector(Vector3.new(0, 5, 0), Vector3.new(0, 5, 0), Color3.new(1, 0, 1))
end)
```

## Config
```luau
type config = {
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
```