package commands;

import haxe.ds.StringMap;
import massive.sys.cmd.Command;
import sys.FileSystem;
import utils.CommandUtils;
import utils.ProjectUtils;
import utils.TemplateUtils;
import FlxTools.IDE;
using StringTools;

class TemplateCommand extends Command
{
	private var autoContinue:Bool = false;
	private var ideOption:IDE = IDE.NONE;

	override public function execute():Void
	{
		if (!FlxTools.templatesLoaded)
		{
			Sys.println("Error loading templates, please run 'flixel download'.");
			return;
		}
		
		var targetPath = "";
		var templateName = "";

		if (console.args[1] != null)
			templateName = console.args[1];

		if (console.args[2] != null)
			targetPath = console.args[2];

		if (console.getOption("-y") != null)
			autoContinue = true;

		ideOption = getSelectedIDE();

		if (console.getOption("-n") != null)
		{
			targetPath = console.getOption("-n");
		}

		//support a path as an arg without name for default
		//flixel t ./<new_directory> <options>
		if (templateName.startsWith("./"))
		{
			targetPath = templateName;
			templateName = "";
		}

		processTemplate(templateName, targetPath);
	}

	public function processTemplate(TemplateName:String = "", TargetPath:String = ""):Void
	{
		var template:TemplateProject = TemplateUtils.get(TemplateName);

		if (template == null)
		{
			error("Error getting the template with the name of " + TemplateName +
				" make sure you have installed flixel-templates ('haxelib install flixel-templates')");
		}
		else
		{
			TemplateName = template.Name;
		}

		//override the template defaults form the command arguments
		template = addOptionReplacement(template);

		if (TargetPath == "")
		{
			TargetPath = Sys.getCwd() + TemplateName;
		}
		else if (!TargetPath.startsWith("/"))
		{
			TargetPath = CommandUtils.combine(Sys.getCwd(), CommandUtils.stripPath(TargetPath));
		}

		if (FileSystem.exists(TargetPath))
		{
			Sys.println("Warning::" + TargetPath);

			var answer = Answer.Yes;

			if (!autoContinue)
			{
				answer = CommandUtils.askYN("Directory exists - do you want to delete it first?");
			}

			if (answer == Answer.Yes)
			{
				CommandUtils.deleteRecursively(TargetPath);
			}
		}

		template.Template.replacements = ProjectUtils.copyIDETemplateFiles(TargetPath, template.Template.replacements, ideOption);

		CommandUtils.copyRecursively(template.Path, TargetPath, TemplateUtils.TemplateFilter, true);

		TemplateUtils.modifyTemplateProject(TargetPath, template);

		Sys.println(" Created Template at:");
		Sys.println(" " + TargetPath);
		Sys.println(" ");

		if (FlxTools.settings.IDEAutoOpen)
		{
			var projectName = TemplateUtils.getReplacementValue(template.Template.replacements, "${PROJECT_NAME}");
			ProjectUtils.openWithIDE(TargetPath, projectName, ideOption);
		}

		exit();
	}

	private function getSelectedIDE():IDE
	{
		var options = [
			"-subl" => IDE.SUBLIME_TEXT,
			"-fd" => IDE.FLASH_DEVELOP,
			"-fdz" => IDE.FLASH_DEVELOP_FDZ,
			"-noide" => IDE.NONE
		];

		var choice = null;
		
		if (FlxTools.settings != null)
		{
			choice = FlxTools.settings.DefaultEditor;
		}

		for (o in options.keys())
		{
			var option = o;
			var IDE = options.get(o);

			var optionGet = console.getOption(option);

			if (optionGet != null)
				choice = IDE;
		}

		return (choice != null) ? choice : IDE.NONE;
	}

	private function addOptionReplacement(Template:TemplateProject):TemplateProject
	{
		var replacements = Template.Template.replacements;

		for (o in replacements)
		{
			var replace = addOptions(o.pattern, o.cmdOption, o.replacement);
			if (replace.replacement != o.replacement)
				o.replacement = replace.replacement;
		}

		return Template;
	}

	private function addOptions(Pattern:String, CMDOption:String, DefaultValue:Dynamic):TemplateReplacement
	{
		var option = console.getOption(CMDOption);

		if (option != null && option != 'true' && option != 'false')
			DefaultValue = option;

		return
		{
			replacement : DefaultValue,
			pattern : Pattern,
			cmdOption : CMDOption
		};
	}
}