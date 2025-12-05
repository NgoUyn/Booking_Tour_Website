using System.Collections.Generic;

namespace Tour_Website.ViewModels
{
    public class CartItemViewModel
    {
        public int CartItemId { get; set; }
        public int TourId { get; set; }
        public string TourName { get; set; } = string.Empty;
        public string AvatarUrl { get; set; } = "/Content/images/Tour/default.jpg";
        public decimal UnitPrice { get; set; }
        public int Quantity { get; set; }
        public decimal SubTotal => UnitPrice * Quantity;
    }

    public class CartViewModel
    {
        public int? CartId { get; set; }
        public List<CartItemViewModel> Items { get; set; } = new List<CartItemViewModel>();

        public decimal Total
        {
            get
            {
                decimal s = 0m;
                foreach (var it in Items) s += it.SubTotal;
                return s;
            }
        }

        public decimal Shipping { get; set; } = 30000m;
        public decimal FinalTotal => Total + Shipping;
    }
}