namespace Tour_Website.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("OrderDetail")]
    public partial class OrderDetail
    {
        public int OrderDetailID { get; set; }

        public int? OrderID { get; set; }

        public int? TourID { get; set; }

        public int? Quantity { get; set; }

        public decimal? UnitPrice { get; set; }

        public virtual Order Order { get; set; }

        public virtual Tour Tour { get; set; }
    }
}
