package ui.modal.panel;

class EditTilesetDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var curTd : Null<data.def.TilesetDef>;


	public function new(?selectedDef:data.def.TilesetDef) {
		super();

		loadTemplate( "editTilesetDefs", "defEditor tilesetDefs" );
		jList = jModalAndMask.find(".mainList ul");
		jForm = jModalAndMask.find("ul.form");
		linkToButton("button.editTilesets");

		// Create tileset
		jModalAndMask.find(".mainList button.create").click( function(ev) {
			var td = project.defs.createTilesetDef();
			selectTileset(td);
			editor.ge.emit( TilesetDefAdded(td) );
			jForm.find("input").first().focus().select();
		});

		selectTileset(selectedDef!=null ? selectedDef : project.defs.tilesets[0]);
	}

	function deleteTilesetDef(td:data.def.TilesetDef) {
		new LastChance(L.t._("Tileset ::name:: deleted", { name:td.identifier }), project);
		var old = td;
		project.defs.removeTilesetDef(td);
		selectTileset(project.defs.tilesets[0]);
		editor.ge.emit( TilesetDefRemoved(old) );
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged(_), LevelSelected(_):
				close();

			case LayerInstanceRestoredFromHistory(li):
				updateList();
				updateForm();
				updateTilesetPreview();

			case TilesetDefChanged(td):
				updateList();
				updateForm();
				updateTilesetPreview();
				if( td==curTd )
					rebuildPixelData();

			case TilesetDefPixelDataCacheRebuilt(td):
				if( td==curTd )
					updateTilesetPreview();

			case _:
		}
	}

	function selectTileset(td:data.def.TilesetDef) {
		curTd = td;
		updateList();
		updateForm();
		updateTilesetPreview();
	}



	function updateTilesetPreview() {
		var jPickerWrapper = jContent.find(".pickerWrapper");

		if( curTd==null ) {
			jPickerWrapper.hide();
			jContent.find(".tilesDemo").hide();
			return;
		}

		jContent.find(".tilesDemo").show();

		// Main tileset view
		jPickerWrapper.show().empty();
		if( curTd.isAtlasLoaded() ) {
			var picker = new TilesetPicker(jPickerWrapper, curTd, ViewOnly);
			picker.renderGrid();
			picker.resetScroll();
		}

		// Demo tiles
		var padding = 8;
		var jDemo = jContent.find(".tilesDemo canvas");
		JsTools.clearCanvas(jDemo);

		if( curTd!=null && curTd.isAtlasLoaded() ) {
			jDemo.attr("width", curTd.tileGridSize*8 + padding*7);
			jDemo.attr("height", curTd.tileGridSize);

			var idx = 0;
			function renderDemoTile(tcx,tcy) {
				curTd.drawTileToCanvas(jDemo, curTd.getTileId(tcx,tcy), (idx++)*(curTd.tileGridSize+padding), 0);
			}
			renderDemoTile(0,0);
			renderDemoTile(1,0);
			renderDemoTile(2,0);
			renderDemoTile(0,1);
			renderDemoTile(0,2);
			renderDemoTile(0,3);
			renderDemoTile(0,4);
		}
	}


	inline function rebuildPixelData() {
		curTd.buildPixelData( Editor.ME.ge.emit.bind(TilesetDefPixelDataCacheRebuilt(curTd)) );
	}


	function updateForm() {
		jForm.find("*").off(); // cleanup event listeners

		if( curTd==null ) {
			jForm.hide();
			// jContent.find(".noTileLayer").hide();
			jContent.find(".none").show();
			return;
		}

		JsTools.parseComponents(jForm);
		jForm.show();
		jContent.find(".none").hide();
		// if( !project.defs.hasLayerType(Tiles) && !project.defs.hasAutoLayer() )
		// 	jContent.find(".noTileLayer").show();
		// else
		// 	jContent.find(".noTileLayer").hide();

		// Image file picker
		jForm.find(".imagePicker").remove();
		var jImg = JsTools.createImagePicker(curTd.relPath, (?relPath)->{
			var oldRelPath = curTd.relPath;
			if( relPath==null ) {
				// Remove image
				if( oldRelPath!=null )
					editor.watcher.stopWatchingRel(oldRelPath);
				curTd.removeAtlasImage();
			}
			else {
				// Load image
				App.LOG.fileOp("Loading atlas: "+project.makeAbsoluteFilePath(relPath));

				var result = curTd.importAtlasImage(relPath);
				switch result {
					case Ok:

					case FileNotFound, LoadingFailed(_):
						new ui.modal.dialog.Warning( Lang.atlasLoadingMessage(relPath, result) );
						return;

					case TrimmedPadding, RemapLoss, RemapSuccessful:
						new ui.modal.dialog.Message( Lang.atlasLoadingMessage(relPath, result), "tile" );
				}

				if( oldRelPath!=null )
					editor.watcher.stopWatchingRel(oldRelPath);
				editor.watcher.watchImage(curTd.relPath);
				project.defs.autoRenameTilesetIdentifier(oldRelPath, curTd);
			}

			updateTilesetPreview();
			editor.ge.emit( TilesetDefChanged(curTd) );
		});
		jImg.insertAfter( jForm.find("li.img>label:first") );


		// Fields
		var i = Input.linkToHtmlInput(curTd.identifier, jForm.find("input[name='name']") );
		i.fixValue = (v)->project.makeUniqueIdStr(v, (id)->project.defs.isTilesetIdentifierUnique(id,curTd));
		i.onChange = editor.ge.emit.bind( TilesetDefChanged(curTd) );

		var i = Input.linkToHtmlInput( curTd.tileGridSize, jForm.find("input[name=tilesetGridSize]") );
		i.linkEvent( TilesetDefChanged(curTd) );
		i.setBounds(2, curTd.getMaxTileGridSize());

		var i = Input.linkToHtmlInput( curTd.spacing, jForm.find("input[name=spacing]") );
		i.linkEvent( TilesetDefChanged(curTd) );
		i.setBounds(0, curTd.getMaxTileGridSize());

		var i = Input.linkToHtmlInput( curTd.padding, jForm.find("input[name=padding]") );
		i.linkEvent( TilesetDefChanged(curTd) );
		i.setBounds(0, curTd.getMaxTileGridSize());
	}


	function updateList() {
		jList.empty();

		for(td in project.defs.tilesets) {
			var e = new J("<li/>");
			jList.append(e);

			e.append('<span class="name">'+td.identifier+'</span>');
			if( curTd==td )
				e.addClass("active");

			e.click( function(_) selectTileset(td) );

			ContextMenu.addTo(e, [
				{
					label: L._Duplicate(),
					cb: ()-> {
						var copy = project.defs.duplicateTilesetDef(td);
						editor.ge.emit( TilesetDefAdded(copy) );
						selectTileset(copy);
					},
				},
				{
					label: L._Delete(),
					cb: deleteTilesetDef.bind(td),
				},
			]);
		}
	}
}
