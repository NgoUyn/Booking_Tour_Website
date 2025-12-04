using System.Collections.Generic;

namespace Tour_Website.ViewModels
{
	public class TuTucViewModel
	{
		public List<CategoryOption> Categories { get; set; } = new List<CategoryOption>();
		public List<PlaceCard> Places { get; set; } = new List<PlaceCard>();

		public class CategoryOption
		{
			public int CategoryId { get; set; }
			public string Name { get; set; } = string.Empty;
			public string Slug { get; set; } = string.Empty;
		}

		public class PlaceCard
		{
			public int PlaceId { get; set; }
			public string Name { get; set; } = string.Empty;
			public string Address { get; set; } = string.Empty;
			public double Latitude { get; set; }
			public double Longitude { get; set; }
			public double Rating { get; set; }
			public int Reviews { get; set; }
			public string PhotoUrl { get; set; } = string.Empty;
			public List<string> ImageUrls { get; set; } = new List<string>();
			public string Description { get; set; } = string.Empty;
			public string CategorySlug { get; set; } = "other";
			public string CategoryName { get; set; } = string.Empty;
			public double? Distance { get; set; }
		}
	}
}
