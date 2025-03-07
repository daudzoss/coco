#include "c2/motorola/6809.h"

class c2_project_ustack : public motorola6809
{
public:
	c2_project_ustack(cmdi *pcmd):motorola6809(pcmd){}

C2_SECTION_TOP

	void c2_pass() override
	{
		C2_SECTION_ASM
		{
			#include "ustack.s"
		}
	}

	void c2_pre() override
	{
		motorola6809::c2_pre();
		// Insert custom pre-pass code here
	}

	void c2_post() override
	{
		motorola6809::c2_post();
		// Insert custom post-pass code here
	}

	const char *c2_get_template() override
	{
		return "6809";
	}
};

c2i *c2_create_object_instance(cmdi *pcmd) {return new c2_project_ustack(pcmd);}
