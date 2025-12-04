using System.Collections.Generic;

namespace Tour_Website.ViewModels
{
	public class TourNhomViewModel
	{
		public List<TourCard> Tours { get; set; } = new List<TourCard>();
		public List<CategoryOption> Categories { get; set; } = new List<CategoryOption>();

		public class TourCard
		{
			public int TourId { get; set; }
			public string TourName { get; set; } = string.Empty;
			public string Description { get; set; } = string.Empty;
			public string Duration { get; set; } = string.Empty;
			public decimal Price { get; set; }
			public int TotalSlots { get; set; }
			public int AvailableSlots { get; set; }
			public int SoldCount { get; set; }
			public string AvatarUrl { get; set; } = "/Content/images/tours/default.jpg";
			public string CategoryName { get; set; } = "Tour";
			public List<ItineraryItem> Itinerary { get; set; } = new List<ItineraryItem>();
		}

		public class ItineraryItem
		{
			public int DayNumber { get; set; }
			public string Title { get; set; } = string.Empty;
			public string Description { get; set; } = string.Empty;
		}

		public class CategoryOption
		{
			public int CategoryId { get; set; }
			public string Name { get; set; } = string.Empty;
			public string Slug { get; set; } = string.Empty;
		}
	}
}
