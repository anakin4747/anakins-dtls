#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>

static const struct of_device_id widget_a_of_match[] = {
	{ .compatible = "vendor,widget-a" },
	{ }
};
MODULE_DEVICE_TABLE(of, widget_a_of_match);

static struct platform_driver widget_a_driver = {
	.driver = {
		.name = "widget-a",
		.of_match_table = widget_a_of_match,
	},
};
module_platform_driver(widget_a_driver);
