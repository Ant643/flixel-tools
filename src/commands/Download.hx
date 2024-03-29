package commands;

import massive.sys.cmd.Command;
import utils.CommandUtils;

class Download extends Command
{
	override public function execute()
	{
		CommandUtils.haxelibCommand("flixel-addons", true);
		CommandUtils.haxelibCommand("flixel-demos", true);
		CommandUtils.haxelibCommand("flixel-templates", true);
		CommandUtils.haxelibCommand("flixel-ui", true);

		exit();
	}
}
