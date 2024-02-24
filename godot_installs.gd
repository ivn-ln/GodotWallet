extends VBoxContainer


@onready var select_import_file = $SelectImportFile
@onready var installs_container = $GodotInstalls/ScrollContainer/InstallsContainer
@onready var downloads_container = $GodotInstalls/ScrollContainer/DownloadsContainer
@onready var install_actions_container = $GodotInstalls/InstallActionsContainer
@onready var confirmation_dialog = $ConfirmationDialog
@onready var http = $HTTPreq
@onready var button_refresh = $ActionsContainer/ButtonRefresh
@onready var button_download = $GodotInstalls/InstallActionsContainer/ButtonDownload
@onready var button_run = $GodotInstalls/InstallActionsContainer/ButtonRun
@onready var button_remove = $GodotInstalls/InstallActionsContainer/ButtonRemove
@onready var loading = $GodotInstalls/ScrollContainer/Loading
@onready var http_download = $HTTPDownload
@onready var progress = $Progress
@onready var progress_bar = $Progress/Control/ProgressBar
const INSTALL_ENTRY = preload("res://install_entry.tscn")
const DOWNLOAD_ENTRY = preload("res://download_entry.tscn")
var installs_array = []
var versions_array = []
var install_config = ConfigFile.new()
var selected_entry
var selected_download_entry
var versions_not_fetched = true
var stable_only = true
var mono = false
var download_started = false
var hide_installed = true


func _ready():
	if FileAccess.file_exists(Globals.installs_cfg_path):
		install_config.load(Globals.installs_cfg_path)
		for section in install_config.get_sections():
			add_install(section)


func _on_button_import_pressed():
	select_import_file.show()


func _on_select_import_file_file_selected(path: String):
	var version = add_install(path)
	install_config.set_value(path, 'version', version)
	install_config.save(Globals.installs_cfg_path)
	#get_tree().reload_current_scene()


func add_install(path):
	path = ProjectSettings.globalize_path(path)
	if path in installs_array:
		OS.alert('This godot install was already imported!')
		return
	if not '.exe' in path:
		OS.alert('Could not import selected file, it is not an executable!')
		return
	var output = []
	var godotArguments = ["--version"]
	var godotPath = path
	OS.execute(godotPath, godotArguments, output, false, false)
	var install_name = ''
	var version_splitted = output[0].split('.')
	var splitted_id = 0
	while version_splitted[splitted_id].is_valid_int():
		install_name += version_splitted[splitted_id] + '.'
		splitted_id+=1
	install_name = install_name.trim_suffix('.')
	var version = install_name
	install_name += ' ' + version_splitted[splitted_id].capitalize() + ' ' + version_splitted[splitted_id+1].capitalize() 
	var install_entry = INSTALL_ENTRY.instantiate()
	installs_container.add_child(install_entry)
	install_entry.set_install_name(install_name)
	install_entry.filepath = path
	install_entry.entry_selected.connect(_on_entry_selected)
	installs_array.append(path)
	versions_array.append({"path": path, "version": version})
	Globals.versions_array = versions_array
	return version


func _on_entry_selected(filepath):
	for entry in installs_container.get_children():
		if filepath == entry.filepath:
			selected_entry = filepath
			continue
		entry.entry_deselect()
	for c in install_actions_container.get_children():
		if c is Button:
			c.disabled = false
	button_download.hide()
	button_remove.show()
	button_run.show()


func _on_button_remove_pressed():
	confirmation_dialog.show()


func _on_confirmation_dialog_confirmed():
	for entry in installs_container.get_children():
		if selected_entry == entry.filepath:
			entry.queue_free()
	install_config.erase_section(selected_entry)
	installs_array.erase(selected_entry)
	var output = []
	var godotArguments = ["--version"]
	var godotPath = selected_entry
	OS.execute(godotPath, godotArguments, output, false, false)
	var install_name = ''
	var version_splitted = output[0].split('.')
	var splitted_id = 0
	while int(version_splitted[splitted_id]) != 0:
		install_name += version_splitted[splitted_id] + '.'
		splitted_id+=1
	for install in versions_array:
		if install['path'] == selected_entry:
			versions_array.erase(install)
	install_name = install_name.trim_suffix('.')
	var version = install_name
	versions_array.erase(version)
	Globals.versions_array = versions_array
	install_config.save(Globals.installs_cfg_path)


func _on_button_run_pressed():
	var thread = Thread.new()
	thread.start(run_selected_install)


func run_selected_install():
	var output = []
	var godotArguments = ["--project-manager"]
	var versionId = '4.2'
	var godotPath = selected_entry
	OS.execute(godotPath, godotArguments, output, false, false)


func get_godot_versions_from_website(url="https://godotengine.org/download/archive/"):
	var request = http.request(url)
	loading.show()
	for c in downloads_container.get_children():
		c.queue_free()
	if request != OK:
		OS.alert('An error has occured!')
		return

func _on_htt_preq_request_completed(result, response_code, headers, body):
	if result!= 0:
		OS.alert('An error has occured!')
	var json = JSON.new()
	var html = body.get_string_from_utf8()
	var start = html.find('<div class="container">')
	var end = html.find('</main>')
	html = html.substr(start, end-start)
	var fetched_arr = []
	while html.find('<div class="archive-list-item">') != -1:
		var search_keyword = '<a class="archive-version" href="'
		var end_keyword = '" title="Open downloads page">'
		var url_start = html.find(search_keyword) + search_keyword.length()
		var url_len = html.find(end_keyword) - url_start
		var url = html.substr(url_start, url_len) 
		var version = url.trim_prefix('/download/archive/')
		html = html.substr(url_start + url_len + end_keyword.length())
		var is_existing = false
		if hide_installed:
			for version_ in versions_array:
				if version_['version'] in version:
					if version.find(version_['version']) + version_['version'].length() < version.length():
						if version[version.find(version_['version']) + version_['version'].length()] != '.':
							is_existing = true
							break
		if is_existing:
			continue
		if not 'stable' in version and stable_only:
			continue
		fetched_arr.append({"url": url, "version": version})
	for version in fetched_arr:
		var download_entry = DOWNLOAD_ENTRY.instantiate()
		download_entry.set_install_name(version["version"])
		download_entry.url = version['url']
		downloads_container.add_child(download_entry)
		download_entry.download_selected.connect(_on_download_selected)
	loading.hide()


func _on_download_selected(url):
	for entry in downloads_container.get_children():
		if url == entry.url:
			selected_download_entry = url
			continue
		entry.entry_deselect()
	for c in install_actions_container.get_children():
		if c is Button:
			c.disabled = false
	button_download.show()
	button_remove.hide()
	button_run.hide()


func _on_button_web_browser_toggled(toggled_on):
	button_refresh.disabled = not toggled_on
	if toggled_on:
		installs_container.hide()
		downloads_container.show()
		get_godot_versions_from_website()
	else:
		installs_container.show()
		downloads_container.hide()


func _on_check_box_toggled(toggled_on):
	stable_only = toggled_on


func _on_button_refresh_pressed():
	for c in downloads_container.get_children():
		c.queue_free()
	get_godot_versions_from_website()


func _on_button_download_pressed():
	if download_started:
		OS.alert('Download has already started!')
		return
	progress.show()
	progress_bar.value = 0
	if not DirAccess.dir_exists_absolute("user://Installs"):
		DirAccess.make_dir_absolute("user://Installs")
	var version_name = 'user://Installs/Godot_v' + selected_download_entry.split('/')[3] + '.zip'
	create_tween().tween_property(progress_bar, "value", 99, 10).set_ease(Tween.EASE_IN)
	if not FileAccess.file_exists(version_name):
		http_download.set_download_file(version_name)
		var mono_string = ""
		if mono:
			mono_string = "_mono"
		var link = "https://github.com/godotengine/godot-builds/releases/download/" + selected_download_entry.split('/')[3] + "/Godot_v" + selected_download_entry.split('/')[3] + mono_string + "_win64.exe.zip"
		var request = http_download.request(link)
		download_started = true
		await http_download.request_completed
		progress_bar.value += 5
		if request != OK:
			OS.alert('An error has occured!')
			download_started = false
			progress.hide()
			return
	var reader = ZIPReader.new()
	var e = reader.open(version_name)
	if e != OK:
		OS.alert('Could not unzip the file!')
		download_started = false
		progress.hide()
		return
	var files = reader.get_files()
	var executable = reader.read_file(files[0])
	var file = FileAccess.open('user://Installs/Godot_v' + selected_download_entry.split('/')[3] + '.exe', FileAccess.WRITE)
	file.store_buffer(executable)
	file.close()
	reader.close()
	OS.alert('Godot v' + selected_download_entry.split('/')[3] + ' have been succesfully installed!', 'Success!')
	download_started = false
	progress.hide()
	var install_path = ProjectSettings.globalize_path('user://Installs/Godot_v' + selected_download_entry.split('/')[3] + '.exe')
	var version = add_install(install_path)
	install_config.set_value('user://Installs/Godot_v' + selected_download_entry.split('/')[3] + '.exe', 'version', version)
	install_config.save(Globals.installs_cfg_path)
	_on_button_refresh_pressed()



func _on_hide_installed_toggled(toggled_on):
	hide_installed = toggled_on
