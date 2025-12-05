using System.Web.Mvc;

namespace Tour_Website.Areas.Customer
{
	public class CustomerAreaRegistration : AreaRegistration
	{
		public override string AreaName => "Customer";

		public override void RegisterArea(AreaRegistrationContext context)
		{
			context.MapRoute(
				"Customer_default",
				"Customer/{controller}/{action}/{id}",
				new { controller = "Home", action = "Index", id = UrlParameter.Optional }
			);
		}
	}
}
