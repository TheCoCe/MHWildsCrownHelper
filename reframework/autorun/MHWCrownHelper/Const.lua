local Const = {};

---@type table<string, app.EnemyDef.CrownType>
Const.CrownType = {
    None = 0,
    Small = 1,
    Big = 2,
    King = 3,
}

Const.CrownNames = {
    [Const.CrownType.None] = "Normal",
    [Const.CrownType.Small] = "Small",
    [Const.CrownType.Big] = "Big",
    [Const.CrownType.King] = "King"
}

Const.CrownIcons = {
    [Const.CrownType.None] = "none",
    [Const.CrownType.Small] = "miniCrown",
    [Const.CrownType.Big] = "bigCrown",
    [Const.CrownType.King] = "kingCrown"
}

return Const;
