return {
    ShowDetails = function(name, width, height)
        local initName = name;
        local data = { template = { name=name, width=width, height=height } };
        local dlg = Dialog("Details");

        dlg:entry{
            id="templateName",
            label="Name",
            text=(data.template.name or "New Template"),
            onchange=function() data.template.name = dlg.data.templateName; end
        }:newrow();

        dlg:entry{
            id="templateWidth",
            label="Width",
            decimals=integer,
            text=tostring(data.template.width or 128),
            onchange=function() data.template.width = dlg.data.templateWidth; end
        }:newrow();

        dlg:number{
            id="templateHeight",
            label="Height",
            decimals=integer,
            text=tostring(data.template.height or 128),
            onchange=function() data.template.height = dlg.data.templateHeight; end
        }:newrow();

        dlg:button{
            id="saveChangesButton",
            text="Save Changes",
            onclick=function()
                data.action = "update";
                dlg:close();
            end
        }

        dlg:button{
            id="addNewButton",
            text="Add As New",
            onclick=function()
                if (initName == dlg.data.templateName) then
                    data.action = "update";
                else
                    data.action = "add";
                end
                dlg:close();
            end
        }

        dlg:button{
            id="deleteButton",
            text="Delete",
            onclick=function()
                data.action = "delete";
                dlg:close();
            end
        }

        dlg:show{wait = true};

        return data;
    end
};