extends Resource
class_name ClassPathsData

@export var class_id: String
@export var paths: Array[PathData]

func _ready():
    assert(paths.size() > 0, "No paths assigned in ClassPathsData.")
    for path in paths:
        assert(path != null, "One of the paths is not assigned in ClassPathsData.") 