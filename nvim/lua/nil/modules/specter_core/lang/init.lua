local adapter = require("nil.modules.specter_core.lang_adapter")

-- core languages
adapter.register("lua", require("nil.modules.specter_core.lang.lua"))
adapter.register("python", require("nil.modules.specter_core.lang.python"))
adapter.register("javascript", require("nil.modules.specter_core.lang.javascript"))
adapter.register("typescript", require("nil.modules.specter_core.lang.javascript"))
adapter.register("ruby", require("nil.modules.specter_core.lang.ruby"))
adapter.register("go", require("nil.modules.specter_core.lang.go"))
adapter.register("c", require("nil.modules.specter_core.lang.c"))
adapter.register("cpp", require("nil.modules.specter_core.lang.c"))
adapter.register("rust", require("nil.modules.specter_core.lang.rust"))
adapter.register("bash", require("nil.modules.specter_core.lang.shell"))
adapter.register("sh", require("nil.modules.specter_core.lang.shell"))

adapter.register("json", require("nil.modules.specter_core.lang.json"))
adapter.register("yaml", require("nil.modules.specter_core.lang.yaml"))
adapter.register("yml", require("nil.modules.specter_core.lang.yaml"))

adapter.register("html", require("nil.modules.specter_core.lang.html"))
adapter.register("css", require("nil.modules.specter_core.lang.css"))

return true
