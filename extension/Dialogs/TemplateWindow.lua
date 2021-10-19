local pluginData = ...;

local detailsPopup = dofile(app.fs.joinPath(app.fs.userConfigPath, "extensions", "FW_Templates", "Dialogs", "DetailsWindow.lua"));

local function Show()

    local dlg = Dialog("Templates");
    local templates = {};
    local templateNames = {};
    local templateCount = 0;

    local function Reset()
        pluginData.prefs.lastBounds = dlg.bounds;
        pluginData.prefs.lastSelection = dlg.data.templateDropdown;
        dlg:close();
        Show();
    end

    local function LogTemplates()
        for i, template in ipairs(templates) do
            pluginData.logger.Log(i..": " ..template.name .. " > ".. template.width .." x ".. template.height);
        end
    end

    ----------------------------------------------------------------------------------------
    -- Helper method to get a template by its name.
    ----------------------------------------------------------------------------------------
    local function TryGetTemplate(templateName)
        for i, template in ipairs(templates) do
            if (template.name == templateName) then
                return template;
            end
        end
        if(templateName == nil) then return end
        pluginData.logger.Log("failed to locate template '"..templateName.."'");
    end

    ----------------------------------------------------------------------------------------
    -- Method to save templates to the configuration file.
    ----------------------------------------------------------------------------------------
    local function SaveTemplates()
        pluginData.logger.Log("Saving templates...");
        LogTemplates();
        pluginData.prefs.templatesJson = pluginData.json.encode({data=templates});
        pluginData.logger.Log("Save Complete.");
    end

    ----------------------------------------------------------------------------------------
    -- Saves template data for some initial 'default' templates.
    ----------------------------------------------------------------------------------------
    local function SetDefaultTemplates()
        templates = {
            { width = 256, height=240, name="NES"},
            { width = 256, height=224, name="SNES"},
            { width = 320, height=224, name="Genesis"},
            { width = 160, height=144, name="Gameboy"},
            { width = 240, height=160, name="Gameboy Advanced"},
            { width = 640, height=480, name="GameCube"},
            { width = 128, height=128, name="Pico-8"},
            { width = 480, height=272, name="PSP"},
        };
    end

    ----------------------------------------------------------------------------------------
    -- Method to load templates from the configuration file if present.
    ----------------------------------------------------------------------------------------
    local function LoadTemplates()
        loadedTemplates = false;
        pluginData.logger.Log("Attempting to load template data from prefs..");
        if(pluginData.prefs.templatesJson ~= nil) then
            local loaded = pluginData.json.decode(pluginData.prefs.templatesJson);
            if(loaded ~= nil) then
                templates = loaded.data;
                loadedTemplates = true;
                pluginData.logger.Log("Successfully parsed from json.");
            end
        end

        if loadedTemplates == false then
            SetDefaultTemplates();
        end

        LogTemplates();

        templateCount = 0;
        for i, template in ipairs(templates) do
            templateCount = templateCount + 1;
            templateNames[templateCount] = template.name;
        end

        pluginData.logger.Log("Successfully loaded "..templateCount.." templates");
    end

    ----------------------------------------------------------------------------------------
    -- Returns an array containing all of the template names in order.
    ----------------------------------------------------------------------------------------
    local function GetTemplateNames()
        names = {};
        for i, template in ipairs(templates) do
            names[i] = template.name;
        end
        return names;
    end

    ----------------------------------------------------------------------------------------
    -- Method to update the data for a given template, reloading the popup when complete.
    ----------------------------------------------------------------------------------------
    local function UpdateTemplate(name, newData)
        local template = TryGetTemplate(name);
        if(template == nil) then
            pluginData.logger.Error("Failed to get template of name: "..name);
        else
            template.width = newData.width;
            template.height = newData.height;
            template.name = newData.name;
        end
    end

    ----------------------------------------------------------------------------------------
    -- Method to update the data for a given template, reloading the popup when complete.
    ----------------------------------------------------------------------------------------
    local function RemoveTemplate(name)
        pluginData.logger.Log("Removing template: "..name);
        newTemplates = {};
        j = 1;
        for i, template in ipairs(templates) do
            if template.name ~= name then
                newTemplates[j] = template;
                j = j+1;
            end
        end
        templates = newTemplates;
        pluginData.logger.Log("template removal complete.");
    end

    ----------------------------------------------------------------------------------------
    -- Returns the last selected template name if able, else the first templates name
    ----------------------------------------------------------------------------------------
    local function GetInitialSelection()
        local selection = templateNames[1];
        if(pluginData.prefs.lastSelection ~= nil) then
            local temp = TryGetTemplate(pluginData.prefs.lastSelection);
            if(temp ~= nil) then
                selection = pluginData.prefs.lastSelection;
            end
        end
    end


    ----------------------------------------------------------------------------------------
    -- Toggles the view between file and preset modes.
    ----------------------------------------------------------------------------------------
    local function SetFileDisplayMode(fileMode)
        pluginData.utils.set_visible(dlg, fileMode == false, {"templateDropdown","resetButton","detailsButton","createFromPresetButton"});
        pluginData.utils.set_visible(dlg, fileMode == true, {"createFromFileButton","file"});
    end


    ----------------------------------------------------------------------------------------
    -- Setup the primary display elements of the dialog, selection and details of templates.
    ----------------------------------------------------------------------------------------
    LoadTemplates();

    dlg:radio{
        id="radioPreset",
        text="From Preset",
        selected=true,
        onclick=function()
            SetFileDisplayMode(false);
        end
    };

    dlg:radio{
        id="radioFile",
        text="From File",
        selected=false,
        onclick=function()
            SetFileDisplayMode(true);
        end
    };

    dlg:separator{id="tabSeparator"};

    ----------------------------------------------------------------------------------------
    -- UI for opening from a preset template (simple canvas size data).
    ----------------------------------------------------------------------------------------
    dlg:combobox {
        id = "templateDropdown",
        option = GetInitialSelection(),
        options = GetTemplateNames()
    };

    dlg:button{
        id="resetButton",
        text="Reset To Defaults",
        onclick=function()
            if (pluginData.utils.create_confirm("Reset to default templates?")) == true then
                SetDefaultTemplates();
                SaveTemplates();
                Reset();
            end
        end
    };

    dlg:button{
        id="detailsButton",
        text="Edit",
        onclick=function()
            local selected = TryGetTemplate(dlg.data.templateDropdown);
            local result = detailsPopup.ShowDetails(selected.name, selected.width, selected.height);
            local refresh = true;
            if (result.action == "add") then
                templates[templateCount+1] = result.template;
            elseif (result.action == "delete") then
                refresh = pluginData.utils.create_confirm("Delete template '"..selected.name.."'?");
                if (refresh == true) then
                    RemoveTemplate(result.template.name);
                end
            elseif (result.action == "update") then
                UpdateTemplate(selected.name, result.template);
            end

            if(refresh == true) then
                SaveTemplates();
                Reset();
            end
        end
    };

    dlg:button{
        id="createFromPresetButton",
        text="Create From Selected",
        onclick=function()
            selected = TryGetTemplate(dlg.data.templateDropdown);
            if selected == nil then
                app.alert("Failed to create template.");
            else
                app.command.NewFile {
                    ui=false,
                    width=selected.width,
                    height=selected.height,
                    colorMode=ColorMode.RGB,
                    fromClipboard=false
                };
            dlg:close();
            end
        end
    }:newrow();


    ----------------------------------------------------------------------------------------
    -- UI for opening from a template file (full file copy for detailed templates).
    ----------------------------------------------------------------------------------------

    dlg:file{
        id="file",
        open = true,
        filetypes={"ase", "aseprite"}
    };
    dlg:button{
        id="createFromFileButton",
        text="Create From File",
        onclick=function()
            local original = Sprite{fromFile=dlg.data.file};
            local newSprite = Sprite(original);
            original:close();
            app.activeSprite = newSprite;
            dlg:close();
        end
    }:newrow();

    SetFileDisplayMode(false);

    if (pluginData.prefs.lastBounds == nil) then
        dlg:show{wait=false};
    else
        dlg:show{
        wait=false,
            bounds=pluginData.prefs.lastBounds
        };
    end
end

Show();

