CREATE DATABASE Tour_Project;
GO
USE Tour_Project;
GO

/*===========================================================
= 1. USERS
===========================================================*/
CREATE TABLE Users
(
    UserID INT PRIMARY KEY IDENTITY(1,1),
    UserName NVARCHAR(100) NOT NULL,
    BirthDate DATE,
    Email NVARCHAR(255) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role NVARCHAR(20) DEFAULT 'User',
    AvatarUrl NVARCHAR(255),
    Phone VARCHAR(15),
    Status NVARCHAR(20) DEFAULT 'Active',
    TotalSpent DECIMAL(12,2) DEFAULT 0,
    MemberLevel AS 
        CASE 
            WHEN TotalSpent < 1000 THEN 'Basic'
            WHEN TotalSpent BETWEEN 1000 AND 4999 THEN 'Member'
            ELSE 'VIP'
        END,
    CreatedAt DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);
GO


/*===========================================================
= 2. CATEGORY
===========================================================*/
CREATE TABLE Category
(
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO


/*===========================================================
= 3. PLACE
===========================================================*/
CREATE TABLE Place 
(
    PlaceID BIGINT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(255) NOT NULL,
    CategoryID INT,
    Description NVARCHAR(MAX),
    Address NVARCHAR(255),
    Longitude DECIMAL(10,7),
    Latitude DECIMAL(10,7),
    Source NVARCHAR(255),
    ExternalID NVARCHAR(100),
    AvgRating DECIMAL(3,2),
    RatingCount INT DEFAULT 0,
    CreatedBy INT,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    IsActive BIT DEFAULT 1,

    CONSTRAINT FK_Place_Category FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID),
    CONSTRAINT FK_Place_User FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);
GO


/*===========================================================
= 4. PLACE IMAGE
===========================================================*/
CREATE TABLE PlaceImage
(
    ImageID INT PRIMARY KEY IDENTITY(1,1),
    PlaceID BIGINT,
    Url NVARCHAR(255),
    IsCover BIT DEFAULT 0,
    UploadedBy INT,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT FK_PlaceImage_Place FOREIGN KEY (PlaceID) REFERENCES Place(PlaceID),
    CONSTRAINT FK_PlaceImage_User FOREIGN KEY (UploadedBy) REFERENCES Users(UserID)
);
GO


/*===========================================================
= 5. REVIEW
===========================================================*/
CREATE TABLE Review
(
    ReviewID BIGINT PRIMARY KEY IDENTITY(1,1),
    PlaceID BIGINT,
    UserID INT,
    Rating TINYINT CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(MAX),
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT FK_Review_Place FOREIGN KEY (PlaceID) REFERENCES Place(PlaceID),
    CONSTRAINT FK_Review_User FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO


/*===========================================================
= 6. TOUR (ĐÃ HỢP NHẤT 2 PHIÊN BẢN)
===========================================================*/
CREATE TABLE Tour
(
    TourID INT PRIMARY KEY IDENTITY(1,1),
    TourName NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX),
    Price DECIMAL(18,2) CHECK (Price >= 0),
    Duration NVARCHAR(50),
    StartLocation BIGINT,
    EndLocation BIGINT,
    TotalSlots INT CHECK (TotalSlots > 0),
    AvailableSlots INT CHECK (AvailableSlots >= 0),
    CategoryID INT,
    AvatarUrl NVARCHAR(255),
    Status INT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Tour_Category FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID),
    CONSTRAINT FK_Tour_StartPlace FOREIGN KEY (StartLocation) REFERENCES Place(PlaceID),
    CONSTRAINT FK_Tour_EndPlace FOREIGN KEY (EndLocation) REFERENCES Place(PlaceID)
);
GO


/*===========================================================
= 7. TOUR ITINERARY
===========================================================*/
CREATE TABLE TourItinerary 
(
    ItineraryID INT PRIMARY KEY IDENTITY(1,1),
    TourID INT,
    DayNumber INT,
    Title NVARCHAR(255),
    Description NVARCHAR(MAX),

    CONSTRAINT FK_TourItinerary_Tour FOREIGN KEY (TourID) REFERENCES Tour(TourID)
);
GO


/*===========================================================
= 8. TOUR - PLACE RELATION (SCHEDULE)
===========================================================*/
CREATE TABLE TourPlace
(
    TourID INT,
    PlaceID BIGINT,
    OrderInSchedule INT,
    Primary key(TourID, PlaceID,OrderInSchedule),
    CONSTRAINT FK_TourPlace_Tour FOREIGN KEY (TourID) REFERENCES Tour(TourID),
    CONSTRAINT FK_TourPlace_Place FOREIGN KEY (PlaceID) REFERENCES Place(PlaceID)
);
GO


/*===========================================================
= 9. VOUCHER
===========================================================*/
CREATE TABLE Voucher 
(
    VoucherID INT PRIMARY KEY IDENTITY(1,1),
    Code NVARCHAR(50) UNIQUE,
    Description NVARCHAR(255),
    DiscountPercent DECIMAL(5,2),
    ApplicableLevel NVARCHAR(20),
    ExpiryDate DATETIMEOFFSET,
    IsActive BIT DEFAULT 1
);
GO


/*===========================================================
= 10. CART
===========================================================*/
CREATE TABLE Cart
(
    CartID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT FK_Cart_User FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO


/*===========================================================
= 11. CART ITEM
===========================================================*/
CREATE TABLE CartItem
(
    CartItemID INT PRIMARY KEY IDENTITY(1,1),
    CartID INT,
    TourID INT,
    Quantity INT CHECK (Quantity > 0),
    UnitPrice DECIMAL(12,2),

    CONSTRAINT FK_CartItem_Cart FOREIGN KEY (CartID) REFERENCES Cart(CartID),
    CONSTRAINT FK_CartItem_Tour FOREIGN KEY (TourID) REFERENCES Tour(TourID)
);
GO


/*===========================================================
= 12. FUNCTION: CALCULATE FINAL AMOUNT
===========================================================*/
CREATE FUNCTION CalculateFinalAmount (@TotalAmount DECIMAL(12,2), @VoucherID INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @DiscountPercent DECIMAL(5,2);
    DECLARE @FinalAmount DECIMAL(12,2);

    SELECT @DiscountPercent = DiscountPercent
    FROM Voucher
    WHERE VoucherID = @VoucherID;

    IF @DiscountPercent IS NULL OR @VoucherID IS NULL
        SET @FinalAmount = @TotalAmount;
    ELSE
        SET @FinalAmount = @TotalAmount * (1 - (@DiscountPercent / 100.0));

    RETURN @FinalAmount;
END;
GO


/*===========================================================
= 13. ORDER
===========================================================*/
CREATE TABLE [Order]
(
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    OrderDate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    TotalAmount DECIMAL(12,2),
    VoucherID INT,
    FinalAmount AS (dbo.CalculateFinalAmount(TotalAmount, VoucherID)),
    Status NVARCHAR(20),

    CONSTRAINT FK_Order_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Order_Voucher FOREIGN KEY (VoucherID) REFERENCES Voucher(VoucherID)
);
GO


/*===========================================================
= 14. ORDER DETAIL
===========================================================*/
CREATE TABLE OrderDetail
(
    OrderDetailID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT,
    TourID INT,
    Quantity INT,
    UnitPrice DECIMAL(12,2),

    CONSTRAINT FK_OrderDetail_Order FOREIGN KEY (OrderID) REFERENCES [Order](OrderID),
    CONSTRAINT FK_OrderDetail_Tour FOREIGN KEY (TourID) REFERENCES Tour(TourID)
);
GO


/*===========================================================
= 15. PAYMENT
===========================================================*/
CREATE TABLE Payment
(
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT,
    Amount DECIMAL(12,2),
    PaymentMethod NVARCHAR(50),
    PaymentDate DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    Status NVARCHAR(20),
    TransactionCode NVARCHAR(100),

    CONSTRAINT FK_Payment_Order FOREIGN KEY (OrderID) REFERENCES [Order](OrderID)
);
GO


/*===========================================================
= 16. USER LOCATION
===========================================================*/
CREATE TABLE UserLocation 
(
    LocationID BIGINT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    Latitude DECIMAL(10,7),
    Longitude DECIMAL(10,7),
    Accuracy FLOAT,
    RecordedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    IsCurrent BIT,

    CONSTRAINT FK_UserLocation_User FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO


/*===========================================================
= 17. ROUTE
===========================================================*/
CREATE TABLE [Route]
(
    RouteID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    RouteName NVARCHAR(255),
    CreatedAt DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT FK_Route_User FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO


/*===========================================================
= 18. ROUTE POINT
===========================================================*/
CREATE TABLE RoutePoint 
(
    RoutePointID INT PRIMARY KEY IDENTITY(1,1),
    RouteID INT,
    PlaceID BIGINT,
    OrderInRoute INT,
    DistanceKm DECIMAL(6,2),
    DurationMin INT,

    CONSTRAINT FK_RoutePoint_Route FOREIGN KEY (RouteID) REFERENCES [Route](RouteID),
    CONSTRAINT FK_RoutePoint_Place FOREIGN KEY (PlaceID) REFERENCES Place(PlaceID)
);
GO

CREATE TABLE AdminRole
(
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE   -- Staff, Manager
);
GO

-- Insert quyền mặc định
INSERT INTO AdminRole (RoleName)
VALUES ('Staff'), ('Manager');
GO


/* ============================
   BẢNG ADMIN — THÊM MỚI AN TOÀN
   ============================ */

   CREATE TABLE AdminStaff
(
    AdminID INT IDENTITY(1,1) PRIMARY KEY,
    AdminName NVARCHAR(150) NOT NULL,
    Email NVARCHAR(200) NOT NULL UNIQUE,
    BirthDate DATE NULL,
    PhoneNumber NVARCHAR(20) NULL,
    AvtUrl NVARCHAR(300) NULL,
    RoleID INT NOT NULL,                           -- Khóa ngoại
    Password NVARCHAR(256) NOT NULL,               -- Bạn tạm thời để plain text
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_AdminStaff_Role
        FOREIGN KEY (RoleID) REFERENCES AdminRole(RoleID)
);
GO

 INSERT INTO AdminStaff 
    (AdminName, Email, BirthDate, PhoneNumber, AvtUrl, RoleID, Password)
VALUES
   

    (N'Trần Thị Hương', 'huong.tran@touradmin.com', '1994-09-20',
     '0902334988', 'avt_huong.png', 2, 'manager123'),

    (N'Lê Công Phát', 'phat.le@touradmin.com', '1998-02-10',
     '0978890066', 'avt_phat.png', 1, 'staff123');
GO

-- XÓA DỮ LIỆU 
-- Lưu ý: Phải xóa theo thứ tự ngược lại của FK
DELETE FROM RoutePoint;
DELETE FROM [Route];
DELETE FROM UserLocation;
DELETE FROM Payment;
DELETE FROM OrderDetail;
DELETE FROM [Order];
DELETE FROM CartItem;
DELETE FROM Cart;
DELETE FROM TourPlace;
DELETE FROM TourItinerary;
DELETE FROM Tour;
DELETE FROM Review;
DELETE FROM PlaceImage;
DELETE FROM Place;
DELETE FROM Voucher;
DELETE FROM Category;
DELETE FROM Users;
GO

-- ĐẶT LẠI GIÁ TRỊ TỰ TĂNG (IDENTITY) CHO CÁC BẢNG (TUỲ CHỌN: nếu cần đảm bảo ID bắt đầu từ 1)
DBCC CHECKIDENT ('RoutePoint', RESEED, 0);
DBCC CHECKIDENT ('Route', RESEED, 0);
DBCC CHECKIDENT ('UserLocation', RESEED, 0);
DBCC CHECKIDENT ('Payment', RESEED, 0);
DBCC CHECKIDENT ('OrderDetail', RESEED, 0);
DBCC CHECKIDENT ('[Order]', RESEED, 0);
DBCC CHECKIDENT ('CartItem', RESEED, 0);
DBCC CHECKIDENT ('Cart', RESEED, 0);
DBCC CHECKIDENT ('TourItinerary', RESEED, 0);
DBCC CHECKIDENT ('Tour', RESEED, 0);
DBCC CHECKIDENT ('Review', RESEED, 0);
DBCC CHECKIDENT ('PlaceImage', RESEED, 0);
DBCC CHECKIDENT ('Place', RESEED, 0);
DBCC CHECKIDENT ('Voucher', RESEED, 0);
DBCC CHECKIDENT ('Category', RESEED, 0);
DBCC CHECKIDENT ('Users', RESEED, 0);
DBCC CHECKIDENT ('AdminStaff', RESEED, 0);
DBCC CHECKIDENT ('AdminRole', RESEED, 0);

GO


-----------------------------------------------------------
-- 1. USERS
-----------------------------------------------------------
INSERT INTO Users (UserName, BirthDate, Email, PasswordHash, Role, AvatarUrl, Phone, Status, TotalSpent, CreatedAt, IsActive) VALUES 
(N'Nguyễn Văn An', '1990-05-15', 'nguyenvanan@email.com', 'pass1', 'User', 'chandungnam.png', '0901234567', 'Active', 0, GETDATE(), 1),
(N'Trần Thị Bình', '1985-08-22', 'tranthibinh@email.com', 'pass2', 'Admin', 'chandungnu.png', '0912345678', 'Active', 3500, GETDATE(), 1),
(N'Lê Hoàng Cường', '1995-12-10', 'lehoangcuong@email.com', 'pass3', 'User', 'chandungnam.png', '0923456789', 'Active', 8500, GETDATE(), 1),
(N'Phạm Thị Dung', '1988-03-30', 'phamthidung@email.com', 'pass4', 'User', 'chandungnu.png', '0934567890', 'Active', 450, GETDATE(), 1),
(N'Hoàng Văn Em', '1992-07-18', 'hoangvanem@email.com', 'pass5', 'User', 'chandungnam.png', '0945678901', 'Active', 12000, GETDATE(), 1),
(N'Nguyễn Thị Giao', '1998-11-01', 'nguyenthi.giao@email.com', 'pass6', 'User', 'chandungnu.png', '0956123789', 'Active', 1500, GETDATE(), 1),
(N'Trịnh Văn Hùng', '1975-04-20', 'trinhvan.hung@email.com', 'pass7', 'User', 'chandungnam.png', '0967890123', 'Active', 750, GETDATE(), 1),
(N'Bùi Thị Kỷ', '2000-09-09', 'buit.ky@email.com', 'pass8', 'User', 'chandungnu.png', '0978901234', 'Active', 5500, GETDATE(), 1),
(N'Đỗ Văn Lâm', '1993-01-14', 'dovan.lam@email.com', 'pass9', 'User', 'chandungnam.png', '0989012345', 'Inactive', 0, GETDATE(), 0),
(N'Vũ Thị Mai', '1980-06-25', 'vuthi.mai@email.com', 'pass10', 'User', 'chandungnu.png', '0990123456', 'Active', 15000, GETDATE(), 1),
(N'Phan Văn Nam', '1996-03-05', 'phanvan.nam@email.com', 'pass11', 'User', 'chandungnam.png', '0900112233', 'Active', 3200, GETDATE(), 1),
(N'Lý Thị Oanh', '1991-10-17', 'lythi.oanh@email.com', 'pass12', 'User', 'chandungnu.png', '0911223344', 'Active', 900, GETDATE(), 1),
(N'Đặng Quốc Phong', '1983-02-08', 'dangquoc.phong@email.com', 'pass13', 'User', 'chandungnam.png', '0922334455', 'Active', 10000, GETDATE(), 1),
(N'Tô Thị Quyên', '1997-07-28', 'tothi.quyen@email.com', 'pass14', 'User', 'chandungnu.png', '0933445566', 'Active', 250, GETDATE(), 1),
(N'Hồ Văn Sơn', '1989-12-03', 'hovan.son@email.com', 'pass15', 'User', 'chandungnam.png', '0944556677', 'Active', 4800, GETDATE(), 1);
GO             

-----------------------------------------------------------
-- 2. CATEGORY
-----------------------------------------------------------
INSERT INTO Category (CategoryName, Description, IsActive, CreatedAt) VALUES
(N'Đồ ăn', N'Các quán ăn, nhà hàng, ẩm thực địa phương', 1, GETDATE()),
(N'Địa điểm vui chơi', N'Công viên, khu giải trí, trung tâm mua sắm', 1, GETDATE()),
(N'Danh lam thắng cảnh', N'Di tích lịch sử, cảnh quan thiên nhiên', 1, GETDATE()),
(N'Khách sạn/Nghỉ dưỡng', N'Các loại hình lưu trú: hotel, resort, homestay', 1, GETDATE()),
(N'Tour trong nước', N'Các tour du lịch trọn gói tại Việt Nam', 1, GETDATE()),
(N'Hoạt động dã ngoại', N'Cắm trại, leo núi, trekking', 1, GETDATE()),
(N'Bảo tàng/Triển lãm', N'Các địa điểm văn hóa, lịch sử', 1, GETDATE()),
(N'Cafe/Giải khát', N'Quán cà phê, trà sữa, bar', 1, GETDATE()),
(N'Phương tiện di chuyển', N'Dịch vụ thuê xe, tàu, thuyền', 1, GETDATE()),
(N'Lễ hội/Sự kiện', N'Thông tin về các lễ hội diễn ra', 1, GETDATE()),
(N'Tour nước ngoài', N'Các tour du lịch trọn gói quốc tế', 1, GETDATE()),
(N'Thủ công/Truyền thống', N'Làng nghề, xưởng sản xuất truyền thống', 1, GETDATE()),
(N'Khu mua sắm', N'Chợ, trung tâm thương mại', 1, GETDATE()),
(N'Spa/Chăm sóc sức khỏe', N'Dịch vụ làm đẹp, thư giãn', 1, GETDATE()),
(N'Công trình kiến trúc', N'Các tòa nhà, cầu, nhà thờ nổi tiếng', 1, GETDATE());
GO

-----------------------------------------------------------
-- 3. PLACE 
-----------------------------------------------------------
INSERT INTO Place (Name, CategoryID, Description, Address, Longitude, Latitude, Source, ExternalID, AvgRating, RatingCount, CreatedBy, CreatedAt, IsActive) VALUES
(N'Bãi biển Mỹ Khê', 3, N'Một trong những bãi biển đẹp nhất Đà Nẵng', N'Đường Võ Nguyên Giáp, TP. Đà Nẵng', 108.2435000, 16.0601000, N'Admin', NULL, 4.70, 1250, 1, SYSDATETIMEOFFSET(), 1),
(N'Phố Cổ Hội An', 3, N'Khu phố cổ được UNESCO công nhận', N'Phường Minh An, Hội An, Quảng Nam', 108.3283000, 15.8794000, N'Admin', NULL, 4.85, 3000, 1, SYSDATETIMEOFFSET(), 1),
(N'Quán Ăn Bà Dưỡng', 1, N'Bánh xèo nổi tiếng Đà Nẵng', N'K280/23 Hoàng Diệu, Đà Nẵng', 108.2140000, 16.0520000, N'API', 'DN_123', 4.50, 500, 2, SYSDATETIMEOFFSET(), 1),
(N'Khách sạn Mường Thanh', 4, N'Khách sạn ven biển Đà Nẵng', N'Đường Võ Nguyên Giáp, Đà Nẵng', 108.2440000, 16.0610000, N'Admin', NULL, 4.20, 800, 1, SYSDATETIMEOFFSET(), 1),
(N'Sun World Ba Na Hills', 2, N'Khu du lịch và giải trí trên đỉnh núi', N'Hòa Ninh, Hòa Vang, Đà Nẵng', 107.9902000, 16.0270000, N'Admin', 'BH_456', 4.60, 2500, 1, SYSDATETIMEOFFSET(), 1),
(N'Phố đi bộ Nguyễn Huệ', 2, N'Khu phố trung tâm sôi động của Sài Gòn', N'Quận 1, TP. Hồ Chí Minh', 106.6990000, 10.7766000, N'Admin', NULL, 4.55, 1500, 1, SYSDATETIMEOFFSET(), 1),
(N'Dinh Độc Lập', 3, N'Di tích lịch sử quan trọng tại TP.HCM', N'135 Nam Kỳ Khởi Nghĩa, Quận 1, TP.HCM', 106.6960000, 10.7788000, N'Admin', NULL, 4.75, 900, 2, SYSDATETIMEOFFSET(), 1),
(N'Lăng Chủ Tịch Hồ Chí Minh', 3, N'Nơi yên nghỉ của Chủ tịch Hồ Chí Minh', N'Quận Ba Đình, Hà Nội', 105.8340000, 21.0368000, N'Admin', NULL, 4.80, 2000, 3, SYSDATETIMEOFFSET(), 1),
(N'Hồ Gươm (Hồ Hoàn Kiếm)', 3, N'Biểu tượng trung tâm của Hà Nội', N'Quận Hoàn Kiếm, Hà Nội', 105.8520000, 21.0289000, N'Admin', NULL, 4.60, 1800, 1, SYSDATETIMEOFFSET(), 1),
(N'Nhà hàng Chay Thiện Duyên', 1, N'Nhà hàng chay được yêu thích', N'Quận 3, TP. Hồ Chí Minh', 106.6870000, 10.7850000, N'API', NULL, 4.40, 300, 4, SYSDATETIMEOFFSET(), 1),
(N'Công viên Suối Tiên', 2, N'Khu vui chơi giải trí với chủ đề lịch sử', N'Quận 9, TP. Hồ Chí Minh', 106.8200000, 10.8800000, N'API', NULL, 4.10, 600, 1, SYSDATETIMEOFFSET(), 1),
(N'Chợ Bến Thành', 8, N'Chợ truyền thống và biểu tượng của TP.HCM', N'Quận 1, TP. Hồ Chí Minh', 106.6950000, 10.7725000, N'Admin', NULL, 4.30, 1000, 2, SYSDATETIMEOFFSET(), 1),
(N'Bảo tàng Lịch sử Quốc gia', 7, N'Bảo tàng lớn ở Hà Nội', N'Quận Hoàn Kiếm, Hà Nội', 105.8550000, 21.0298000, N'Admin', NULL, 4.65, 450, 5, SYSDATETIMEOFFSET(), 1),
(N'Quán Cafe Cộng Cà Phê', 8, N'Chuỗi cà phê nổi tiếng', N'Đường Lý Tự Trọng, TP. Hồ Chí Minh', 108.2000000, 16.0000000, N'API', NULL, 4.25, 1100, 1, SYSDATETIMEOFFSET(), 1),
(N'Cầu Rồng Đà Nẵng', 15, N'Công trình kiến trúc độc đáo', N'Đường Võ Văn Kiệt, Đà Nẵng', 108.2270000, 16.0660000, N'Admin', NULL, 4.70, 1300, 1, SYSDATETIMEOFFSET(), 1);
GO

-----------------------------------------------------------
-- 4. PLACE IMAGE 
-----------------------------------------------------------
INSERT INTO PlaceImage (PlaceID, Url, IsCover, UploadedBy, CreatedAt) VALUES
(1, N'1.jpg', 1, 1, SYSDATETIMEOFFSET()),
(2, N'2.jpg', 0, 1, SYSDATETIMEOFFSET()),
(3, N'3.jpg', 1, 2, SYSDATETIMEOFFSET()),
(4, N'4.jpg', 0, 1, SYSDATETIMEOFFSET()),
(5, N'5.jpg', 1, 1, SYSDATETIMEOFFSET()),
(6, N'6.jpg', 1, 1, SYSDATETIMEOFFSET()),
(7, N'7.jpg', 1, 2, SYSDATETIMEOFFSET()),
(8, N'8.jpg', 1, 3, SYSDATETIMEOFFSET()),
(9, N'9.jpg', 0, 1, SYSDATETIMEOFFSET()),
(10, N'10.jpg', 1, 4, SYSDATETIMEOFFSET()),
(11, N'11.jpg', 1, 1, SYSDATETIMEOFFSET()),
(12, N'12.jpg', 1, 2, SYSDATETIMEOFFSET()),
(13, N'13.jpg', 0, 5, SYSDATETIMEOFFSET()),
(14, N'14.jpg', 0, 1, SYSDATETIMEOFFSET()),
(15, N'15.jpg', 1, 1, SYSDATETIMEOFFSET());
GO

-----------------------------------------------------------
-- 5. REVIEW 
-----------------------------------------------------------
INSERT INTO Review (PlaceID, UserID, Rating, Comment, CreatedAt) VALUES
(1, 2, 5, N'Bãi biển tuyệt vời, nước trong xanh!', SYSDATETIMEOFFSET()),
(2, 4, 5, N'Phố cổ rất đẹp và yên bình vào buổi tối.', SYSDATETIMEOFFSET()),
(3, 3, 4, N'Bánh xèo ngon, nhưng hơi đông khách.', SYSDATETIMEOFFSET()),
(5, 1, 5, N'Trải nghiệm cáp treo tuyệt vời. Cảnh quan đẹp.', SYSDATETIMEOFFSET()),
(4, 5, 4, N'Phòng sạch sẽ, vị trí đẹp.', SYSDATETIMEOFFSET()),
(6, 6, 5, N'Không gian rộng rãi, rất thích hợp đi dạo cuối tuần.', SYSDATETIMEOFFSET()),
(7, 7, 5, N'Kiến trúc tuyệt đẹp, lịch sử hào hùng.', SYSDATETIMEOFFSET()),
(8, 8, 5, N'Rất trang nghiêm và thiêng liêng.', SYSDATETIMEOFFSET()),
(9, 9, 4, N'Cảnh quan lãng mạn, nhưng hơi đông vào buổi tối.', SYSDATETIMEOFFSET()),
(10, 10, 4, N'Đồ ăn chay rất ngon và thanh tịnh. Giá hợp lý.', SYSDATETIMEOFFSET()),
(11, 6, 3, N'Khu vui chơi hơi cũ, nhưng vẫn nhiều trò.', SYSDATETIMEOFFSET()),
(12, 7, 4, N'Chợ truyền thống có đủ mọi thứ, nên trả giá.', SYSDATETIMEOFFSET()),
(13, 8, 5, N'Trưng bày rất khoa học và hấp dẫn.', SYSDATETIMEOFFSET()),
(14, 9, 4, N'Cà phê đậm đà, không gian retro độc đáo.', SYSDATETIMEOFFSET()),
(15, 10, 5, N'Cầu Rồng phun lửa/nước vào cuối tuần rất ấn tượng!', SYSDATETIMEOFFSET());
GO

-----------------------------------------------------------
-- 6. TOUR
-----------------------------------------------------------
INSERT INTO Tour (TourName, Description, Price, Duration, StartLocation, EndLocation, TotalSlots, AvailableSlots, CategoryID, AvatarUrl, Status, CreatedAt) VALUES
(N'Đà Nẵng - Hội An 3N2Đ', N'Khám phá 2 di sản miền Trung', 3500000.00, N'3 ngày 2 đêm', 1, 2, 30, 25, 5, 'T1.jpg', 1, GETDATE()),
(N'Khám Phá Bà Nà Hills Trong Ngày', N'Đi cáp treo, thăm Cầu Vàng', 1200000.00, N'1 ngày', 5, 5, 50, 48, 5, 'T2.jpg', 1, GETDATE()),
(N'Tour Phú Quốc 5N4Đ', N'Nghỉ dưỡng tại thiên đường biển đảo', 8000000.00, N'5 ngày 4 đêm', 1, 1, 20, 20, 5, 'T3.jpg', 1, GETDATE()),
(N'Miền Tây Sông Nước 2N1Đ', N'Thăm chợ nổi, vườn cây ăn trái', 2500000.00, N'2 ngày 1 đêm', 1, 1, 40, 35, 5, 'T4.jpg', 1, GETDATE()),
(N'Du lịch Cao nguyên Mộc Châu 4 ngày', N'Thăm đồi chè, rừng mận', 4500000.00, N'4 ngày 3 đêm', 1, 1, 25, 10, 5, 'T5.jpg', 1, GETDATE()),
(N'Sài Gòn 2 Ngày', N'Tham quan các điểm nổi bật Sài Gòn', 2800000.00, N'2 ngày 1 đêm', 6, 7, 35, 30, 5, 'T6.jpg', 1, GETDATE()),
(N'Hà Nội 4 Ngày', N'Khám phá văn hóa ẩm thực và di tích Hà Nội', 4200000.00, N'4 ngày 3 đêm', 9, 9, 20, 15, 5, 'T7.jpg', 1, GETDATE()),
(N'Trekking Tà Năng - Phan Dũng', N'Hành trình dã ngoại khó quên', 5500000.00, N'3 ngày 2 đêm', 1, 1, 15, 10, 6, 'T8.jpg', 1, GETDATE()),
(N'Tour Du Lịch Thái Lan 5 Ngày', N'Bangkok - Pattaya trọn gói', 12000000.00, N'5 ngày 4 đêm', 1, 1, 40, 40, 11, 'T9.jpg', 1, GETDATE()),
(N'Tour Dubai Cao Cấp 7 Ngày', N'Khám phá sa mạc và kiến trúc hiện đại', 35000000.00, N'7 ngày 6 đêm', 1, 1, 10, 5, 11, 'T10.jpg', 1, GETDATE()),
(N'Du Thuyền Hạ Long 2 Ngày 1 Đêm', N'Nghỉ dưỡng sang trọng trên Vịnh Hạ Long', 6000000.00, N'2 ngày 1 đêm', 1, 1, 30, 20, 5, 'T11.jpg', 1, GETDATE()),
(N'Khám phá Tây Nguyên 5 Ngày', N'Đà Lạt - Buôn Ma Thuột', 7800000.00, N'5 ngày 4 đêm', 1, 1, 20, 18, 5, 'T12.jpg', 1, GETDATE()),
(N'Đà Nẵng City Tour Trong Ngày', N'Tham quan các điểm nổi tiếng Đà Nẵng', 800000.00, N'1 ngày', 15, 15, 50, 45, 5, 'T13.jpg', 1, GETDATE()),
(N'Tour Côn Đảo Tâm Linh 3 Ngày', N'Thăm các di tích lịch sử Côn Đảo', 4900000.00, N'3 ngày 2 đêm', 1, 1, 25, 25, 5, 'T14.jpg', 1, GETDATE()),
(N'Tour Singapore - Malaysia 6 Ngày', N'Khám phá 2 quốc gia Đông Nam Á', 15000000.00, N'6 ngày 5 đêm', 1, 1, 30, 28, 11, 'T15.jpg', 1, GETDATE());
GO

-----------------------------------------------------------
-- 7. TOUR ITINERARY 
-----------------------------------------------------------
INSERT INTO TourItinerary (TourID, DayNumber, Title, Description) VALUES
(1, 1, N'Đà Nẵng - Chùa Linh Ứng', N'Đón khách tại sân bay, thăm Chùa Linh Ứng, tắm biển Mỹ Khê.'),
(1, 2, N'Hội An Cổ Kính', N'Di chuyển đến Hội An, thăm Phố Cổ, thả đèn hoa đăng.'),
(1, 3, N'Bán Đảo Sơn Trà - Tiễn khách', N'Thăm Bán đảo Sơn Trà, mua sắm đặc sản, tiễn khách.'),
(2, 1, N'Khám phá Bà Nà Hills', N'Cáp treo lên đỉnh, tham quan Cầu Vàng, Làng Pháp.'),
(5, 1, N'Hà Nội - Mộc Châu', N'Di chuyển từ Hà Nội lên Mộc Châu, thăm đồi chè.'),
(6, 1, N'Sài Gòn: Dinh Độc Lập - Phố Đi Bộ', N'Tham quan Dinh Độc Lập, chiều dạo Phố đi bộ Nguyễn Huệ.'),
(6, 2, N'Sài Gòn: Chợ Bến Thành - Tiễn khách', N'Mua sắm tại Chợ Bến Thành, ăn trưa và tiễn khách.'),
(7, 1, N'Hà Nội: Lăng Bác - Hồ Gươm', N'Viếng Lăng Bác, thăm Hồ Gươm và Đền Ngọc Sơn.'),
(7, 2, N'Hà Nội: Ẩm thực Phố Cổ', N'Khám phá ẩm thực 36 phố phường, ăn tối Bún chả.'),
(8, 1, N'Tà Năng: Bắt đầu Trekking', N'Di chuyển đến Tà Năng, trekking qua các đồi cỏ.'),
(9, 1, N'Thái Lan: Bangkok - Chùa Vàng', N'Bay đến Bangkok, tham quan Chùa Vàng nổi tiếng.'),
(10, 1, N'Dubai: Khám phá Burj Khalifa', N'Bay đến Dubai, thăm tòa nhà cao nhất thế giới.'),
(11, 1, N'Hạ Long: Check-in Du Thuyền', N'Đón khách, lên du thuyền, ngắm cảnh Vịnh.'),
(12, 1, N'Tây Nguyên: Đà Lạt Mộng Mơ', N'Thăm các vườn hoa và Hồ Xuân Hương.'),
(15, 1, N'Singapore: Garden by the Bay', N'Bay đến Singapore, tham quan khu vườn siêu cây.');
GO

-----------------------------------------------------------
-- 8. TOUR PLACE 
-----------------------------------------------------------
INSERT INTO TourPlace (TourID, PlaceID, OrderInSchedule) VALUES
(1, 1, 1),   -- Tour: Đà Nẵng-Hội An, Điểm dừng 1: Bãi biển Mỹ Khê
(1, 2, 2),   -- Tour: Đà Nẵng-Hội An, Điểm dừng 2: Phố Cổ Hội An
(2, 5, 1),   -- Tour: Bà Nà Hills, Điểm dừng 1: Sun World Ba Na Hills
(5, 3, 1),   -- Tour: Mộc Châu, Điểm dừng 1: Quán Ăn Bà Dưỡng
(5, 4, 2),   -- Tour: Mộc Châu, Điểm dừng 2: Khách sạn Mường Thanh
(6, 6, 1),   -- Tour: Sài Gòn 2 Ngày, Điểm dừng 1: Phố đi bộ Nguyễn Huệ
(6, 7, 2),   -- Tour: Sài Gòn 2 Ngày, Điểm dừng 2: Dinh Độc Lập
(7, 8, 1),   -- Tour: Hà Nội 4 Ngày, Điểm dừng 1: Lăng Chủ Tịch Hồ Chí Minh
(7, 9, 2),   -- Tour: Hà Nội 4 Ngày, Điểm dừng 2: Hồ Gươm (Hồ Hoàn Kiếm)
(7, 13, 3),  -- Tour: Hà Nội 4 Ngày, Điểm dừng 3: Bảo tàng Lịch sử Quốc gia
(9, 14, 1),  -- Tour: Thái Lan 5 Ngày, Điểm dừng 1: Quán Cafe Cộng Cà Phê
(12, 10, 1), -- Tour: Tây Nguyên 5 Ngày, Điểm dừng 1: Nhà hàng Chay Thiện Duyên
(14, 15, 1), -- Tour: Côn Đảo 3 Ngày, Điểm dừng 1: Cầu Rồng Đà Nẵng
(14, 1, 2),  -- Tour: Côn Đảo 3 Ngày, Điểm dừng 2: Bãi biển Mỹ Khê
(15, 12, 1); -- Tour: Sing-Malay 6 Ngày, Điểm dừng 1: Chợ Bến Thành
GO

-----------------------------------------------------------
-- 9. VOUCHER
-----------------------------------------------------------
INSERT INTO Voucher (Code, Description, DiscountPercent, ApplicableLevel, ExpiryDate, IsActive) VALUES
(N'VIP15', N'Giảm 15% cho thành viên VIP', 15.00, N'VIP', '2026-12-31 23:59:59+07:00', 1),
(N'MEMBER10', N'Giảm 10% cho thành viên Member', 10.00, N'Member', '2026-11-30 23:59:59+07:00', 1),
(N'NEWTOUR5', N'Giảm 5% cho tour mới', 5.00, N'Basic', '2025-12-31 23:59:59+07:00', 1),
(N'FREESHIP', N'Giảm giá cho tour đặt trước', 0.00, N'Basic', '2026-06-30 23:59:59+07:00', 1),
(N'TET2026', N'Ưu đãi Tết nguyên đán', 20.00, N'VIP', '2025-02-15 23:59:59+07:00', 0),
(N'BASIC20', N'Giảm 20% cho thành viên Basic', 20.00, N'Basic', '2026-03-30 23:59:59+07:00', 1),
(N'SUMMER10', N'Ưu đãi du lịch hè', 10.00, N'All', '2026-09-01 23:59:59+07:00', 1),
(N'TOURDN25', N'Giảm 25% cho tour Đà Nẵng', 25.00, N'VIP', '2025-10-30 23:59:59+07:00', 1),
(N'HCM10', N'Giảm 10% cho tour HCM', 10.00, N'Member', '2026-04-15 23:59:59+07:00', 1),
(N'VIPFREE', N'Giảm 100% (Free)', 100.00, N'VIP', '2025-08-01 23:59:59+07:00', 0),
(N'OVERSEAS', N'Giảm 15% cho tour nước ngoài', 15.00, N'Member', '2026-12-31 23:59:59+07:00', 1),
(N'HOLIDAY20', N'Giảm 20% cho tất cả', 20.00, N'All', '2026-01-31 23:59:59+07:00', 1),
(N'MINI5', N'Giảm 5% cho tour dưới 2 triệu', 5.00, N'Basic', '2027-01-01 23:59:59+07:00', 1),
(N'FAMILY', N'Ưu đãi nhóm gia đình', 12.00, N'Member', '2026-07-31 23:59:59+07:00', 1),
(N'LASTCALL', N'Giảm giá phút chót', 30.00, N'All', '2025-06-30 23:59:59+07:00', 0);
GO

-----------------------------------------------------------
-- 10. CART 
-----------------------------------------------------------
INSERT INTO Cart (UserID, CreatedAt) VALUES
(2, SYSDATETIMEOFFSET()), -- CartID 1 (Thuộc UserID 2: Trần Thị Bình)
(3, SYSDATETIMEOFFSET()), -- CartID 2 (Thuộc UserID 3: Lê Hoàng Cường)
(4, SYSDATETIMEOFFSET()), -- CartID 3 (Thuộc UserID 4: Phạm Thị Dung)
(1, SYSDATETIMEOFFSET()), -- CartID 4 (Thuộc UserID 1: Nguyễn Văn An)
(5, SYSDATETIMEOFFSET()), -- CartID 5 (Thuộc UserID 5: Hoàng Văn Em)
(6, SYSDATETIMEOFFSET()), -- CartID 6 (Thuộc UserID 6: Nguyễn Thị Giao)
(7, SYSDATETIMEOFFSET()), -- CartID 7 (Thuộc UserID 7: Trịnh Văn Hùng)
(8, SYSDATETIMEOFFSET()), -- CartID 8 (Thuộc UserID 8: Bùi Thị Kỷ)
(9, SYSDATETIMEOFFSET()), -- CartID 9 (Thuộc UserID 9: Đỗ Văn Lâm)
(10, SYSDATETIMEOFFSET());-- CartID 10 (Thuộc UserID 10: Vũ Thị Mai)
GO

-----------------------------------------------------------
-- 11. CART ITEM 
-----------------------------------------------------------
INSERT INTO CartItem (CartID, TourID, Quantity, UnitPrice) VALUES
(1, 1, 1, 3500000.00),  -- Cart 1 (User 2): 1 vé Tour 1 (Đà Nẵng-Hội An)
(1, 11, 1, 6000000.00), -- Cart 1 (User 2): 1 vé Tour 11 (Du Thuyền Hạ Long)
(2, 2, 2, 1200000.00),  -- Cart 2 (User 3): 2 vé Tour 2 (Bà Nà Hills)
(2, 12, 1, 7800000.00), -- Cart 2 (User 3): 1 vé Tour 12 (Tây Nguyên)
(3, 3, 1, 8000000.00),  -- Cart 3 (User 4): 1 vé Tour 3 (Phú Quốc)
(4, 4, 1, 2500000.00),  -- Cart 4 (User 1): 1 vé Tour 4 (Miền Tây)
(5, 5, 1, 4500000.00),  -- Cart 5 (User 5): 1 vé Tour 5 (Mộc Châu)
(6, 6, 2, 2800000.00),  -- Cart 6 (User 6): 2 vé Tour 6 (Sài Gòn)
(6, 13, 2, 800000.00),  -- Cart 6 (User 6): 2 vé Tour 13 (Đà Nẵng City)
(7, 7, 1, 4200000.00),  -- Cart 7 (User 7): 1 vé Tour 7 (Hà Nội)
(7, 14, 4, 4900000.00), -- Cart 7 (User 7): 4 vé Tour 14 (Côn Đảo Tâm Linh)
(8, 8, 1, 5500000.00),  -- Cart 8 (User 8): 1 vé Tour 8 (Trekking)
(8, 15, 1, 15000000.00),-- Cart 8 (User 8): 1 vé Tour 15 (Sing-Malay)
(9, 9, 3, 12000000.00), -- Cart 9 (User 9): 3 vé Tour 9 (Thái Lan)
(10, 10, 1, 35000000.00);-- Cart 10 (User 10): 1 vé Tour 10 (Dubai)
GO

-----------------------------------------------------------
-- 13. ORDER 
-----------------------------------------------------------
-- TotalAmount sẽ được tính từ OrderDetail. Ở đây chèn giá trị giả định.
INSERT INTO [Order] (UserID, OrderDate, VoucherID, Status) VALUES
(1, SYSDATETIMEOFFSET(), 6, N'Paid'),       -- Order 1 (User 1 - Basic): Đã thanh toán, dùng Voucher 6 (BASIC20)
(2, SYSDATETIMEOFFSET(), 2, N'Paid'),       -- Order 2 (User 2 - Member): Đã thanh toán, dùng Voucher 2 (MEMBER10)
(3, SYSDATETIMEOFFSET(), NULL, N'Pending'), -- Order 3 (User 3 - VIP): Chờ xử lý, KHÔNG voucher
(4, SYSDATETIMEOFFSET(), 2, N'Cancelled'),  -- Order 4 (User 4 - Basic): Đã hủy, dùng Voucher 2 (MEMBER10)
(5, SYSDATETIMEOFFSET(), 1, N'Paid'),       -- Order 5 (User 5 - VIP): Đã thanh toán, dùng Voucher 1 (VIP15)
(6, SYSDATETIMEOFFSET(), 9, N'Paid'),       -- Order 6 (User 6 - Member): Đã thanh toán, dùng Voucher 9 (HCM10)
(7, SYSDATETIMEOFFSET(), 3, N'Pending'),	-- Order 7 (User 7 - Basic): Chờ xử lý, dùng Voucher 3 (NEWTOUR5)
(8, SYSDATETIMEOFFSET(), 12, N'Paid'),    	-- Order 8 (User 8 - VIP): Đã thanh toán, dùng Voucher 12 (HOLIDAY20)
(9, SYSDATETIMEOFFSET(), 6, N'Paid'),  		-- Order 9 (User 9 - Basic): Đã thanh toán, dùng Voucher 6 (BASIC20)
(10, SYSDATETIMEOFFSET(), 1, N'Pending'),	-- Order 10 (User 10 - VIP): Chờ xử lý, dùng Voucher 1 (VIP15)
(6, SYSDATETIMEOFFSET(), NULL, N'Paid'),	-- Order 11 (User 6 - Member): Đã thanh toán, KHÔNG voucher
(7, SYSDATETIMEOFFSET(), NULL, N'Paid'),	-- Order 12 (User 7 - Basic): Đã thanh toán, KHÔNG voucher
(8, SYSDATETIMEOFFSET(), 7, N'Paid'),    	-- Order 13 (User 8 - VIP): Đã thanh toán, dùng Voucher 7 (SUMMER10)
(9, SYSDATETIMEOFFSET(), 10, N'Cancelled'),	-- Order 14 (User 9 - Basic): Đã hủy, dùng Voucher 10 (VIPFREE)
(10, SYSDATETIMEOFFSET(), 8, N'Paid');    	-- Order 15 (User 10 - VIP): Đã thanh toán, dùng Voucher 8 (TOURDN25)
GO

-----------------------------------------------------------
-- 14. ORDER DETAIL 
-----------------------------------------------------------
INSERT INTO OrderDetail (OrderID, TourID, Quantity, UnitPrice) VALUES
(1, 1, 2, 3500000.00),  -- Order 1: 2 vé Tour 1 (Đà Nẵng - Hội An)
(2, 2, 2, 1200000.00),  -- Order 2: 2 vé Tour 2 (Bà Nà Hills)
(3, 2, 1, 1200000.00),  -- Order 3: 1 vé Tour 2 (Bà Nà Hills)
(4, 1, 1, 3500000.00),  -- Order 4: 1 vé Tour 1 (Đà Nẵng - Hội An)
(5, 5, 1, 4500000.00),  -- Order 5: 1 vé Tour 5 (Mộc Châu)
(6, 6, 2, 2800000.00),  -- Order 6: 2 vé Tour 6 (Sài Gòn 2 Ngày)
(7, 7, 1, 4200000.00),  -- Order 7: 1 vé Tour 7 (Hà Nội 4 Ngày)
(8, 8, 1, 5500000.00),  -- Order 8: 1 vé Tour 8 (Trekking Tà Năng)
(9, 9, 3, 12000000.00), -- Order 9: 3 vé Tour 9 (Thái Lan)
(10, 10, 1, 35000000.00),-- Order 10: 1 vé Tour 10 (Dubai)
(11, 13, 1, 4900000.00), -- Order 11: 1 vé Tour 13 (Đà Nẵng City)
(12, 14, 4, 800000.00),  -- Order 12: 4 vé Tour 14 (Côn Đảo Tâm Linh)
(13, 11, 1, 6000000.00), -- Order 13: 1 vé Tour 11 (Du Thuyền Hạ Long)
(14, 12, 1, 7800000.00), -- Order 14: 1 vé Tour 12 (Tây Nguyên)
(15, 2, 1, 1200000.00);  -- Order 15: 1 vé Tour 2 (Bà Nà Hills)
GO

-----------------------------------------------------------
-- 15. PAYMENT 
-----------------------------------------------------------
INSERT INTO Payment (OrderID, Amount, PaymentMethod, PaymentDate, Status, TransactionCode) VALUES
(1, 5950000.00, N'Momo', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_MOMO_001'),
(2, 2160000.00, N'VNPay', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_VNPAY_002'),
(3, 1200000.00, N'Bank Transfer', SYSDATETIMEOFFSET(), N'Failed', N'TRANS_BANK_003'),
(4, 3150000.00, N'Credit Card', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_CARD_004'),
(5, 4275000.00, N'Momo', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_MOMO_005'),
(6, 5040000.00, N'Credit Card', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_CARD_006'),
(7, 3990000.00, N'Momo', SYSDATETIMEOFFSET(), N'Pending', N'TRANS_MOMO_007'),
(8, 4400000.00, N'VNPay', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_VNPAY_008'),
(9, 30600000.00, N'Bank Transfer', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_BANK_009'),
(10, 29750000.00, N'Credit Card', SYSDATETIMEOFFSET(), N'Failed', N'TRANS_CARD_010'),
(11, 4900000.00, N'Momo', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_MOMO_011'),
(12, 3200000.00, N'VNPay', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_VNPAY_012'),
(13, 5400000.00, N'Bank Transfer', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_BANK_013'),
(14, 7800000.00, N'Credit Card', SYSDATETIMEOFFSET(), N'Failed', N'TRANS_CARD_014'),
(15, 1140000.00, N'Momo', SYSDATETIMEOFFSET(), N'Completed', N'TRANS_MOMO_015');
GO

-----------------------------------------------------------
-- 16. USER LOCATION 
-----------------------------------------------------------
INSERT INTO UserLocation (UserID, Latitude, Longitude, Accuracy, RecordedAt, IsCurrent) VALUES
(1, 16.0600000, 108.2100000, 5.0, SYSDATETIMEOFFSET(), 1),  -- User 1: Đà Nẵng (Vị trí hiện tại)
(1, 16.0550000, 108.2150000, 10.5, SYSDATETIMEOFFSET(), 0), -- User 1: Đà Nẵng (Vị trí cũ)
(2, 10.7700000, 106.6900000, 8.0, SYSDATETIMEOFFSET(), 1),  -- User 2: TP.HCM (Vị trí hiện tại)
(3, 15.0000000, 108.0000000, 20.0, SYSDATETIMEOFFSET(), 0), -- User 3: Miền Trung (Vị trí cũ)
(4, 10.7700000, 106.6900000, 15.0, SYSDATETIMEOFFSET(), 0), -- User 4: TP.HCM (Vị trí cũ)
(6, 21.0360000, 105.8330000, 7.0, SYSDATETIMEOFFSET(), 1),  -- User 6: Hà Nội (Gần Lăng Bác, Hiện tại)
(7, 10.7788000, 106.6960000, 4.0, SYSDATETIMEOFFSET(), 1),  -- User 7: TP. HCM (Gần Dinh Độc Lập, Hiện tại)
(8, 16.0601000, 108.2435000, 12.0, SYSDATETIMEOFFSET(), 1), -- User 8: Đà Nẵng (Gần Mỹ Khê, Hiện tại)
(9, 15.8794000, 108.3283000, 6.0, SYSDATETIMEOFFSET(), 1),  -- User 9: Hội An (Vị trí hiện tại)
(10, 10.7766000, 106.6990000, 5.0, SYSDATETIMEOFFSET(), 1), -- User 10: TP. HCM (Gần Phố Đi Bộ, Hiện tại)
(11, 16.0520000, 108.2140000, 15.0, SYSDATETIMEOFFSET(), 0),-- User 11: Đà Nẵng (Vị trí cũ)
(12, 10.7700000, 106.6900000, 8.0, SYSDATETIMEOFFSET(), 0), -- User 12: TP.HCM (Vị trí cũ)
(13, 21.0368000, 105.8340000, 5.5, SYSDATETIMEOFFSET(), 0), -- User 13: Hà Nội (Vị trí cũ)
(14, 16.0660000, 108.2270000, 9.0, SYSDATETIMEOFFSET(), 0), -- User 14: Đà Nẵng (Vị trí cũ)
(15, 10.7700000, 106.6900000, 11.0, SYSDATETIMEOFFSET(), 0);-- User 15: TP.HCM (Vị trí cũ)
GO

-----------------------------------------------------------
-- 17. ROUTE 
-----------------------------------------------------------
INSERT INTO [Route] (UserID, RouteName, CreatedAt) VALUES
(1, N'Hành trình Đà Nẵng 3 ngày', SYSDATETIMEOFFSET()),
(2, N'Lộ trình khám phá Sài Gòn', SYSDATETIMEOFFSET()),
(3, N'Tour ẩm thực miền Trung', SYSDATETIMEOFFSET()),
(1, N'Điểm check-in Hội An', SYSDATETIMEOFFSET()),
(4, N'Du lịch biển hè', SYSDATETIMEOFFSET()),
(6, N'Hà Nội Phố Cổ 2 ngày', SYSDATETIMEOFFSET()),
(7, N'Lộ trình ẩm thực Sài Gòn', SYSDATETIMEOFFSET()),
(8, N'Lịch trình tắm biển Đà Nẵng', SYSDATETIMEOFFSET()),
(9, N'Các điểm check-in Hội An', SYSDATETIMEOFFSET()),
(10, N'Lộ trình quanh Quận 1 TP.HCM', SYSDATETIMEOFFSET()),
(11, N'Route về quê', SYSDATETIMEOFFSET()),
(12, N'Đường đi làm', SYSDATETIMEOFFSET()),
(13, N'Lộ trình bảo tàng Hà Nội', SYSDATETIMEOFFSET()),
(14, N'Đường đi chợ', SYSDATETIMEOFFSET()),
(15, N'Route cuối tuần', SYSDATETIMEOFFSET());
GO

-----------------------------------------------------------
-- 18. ROUTE POINT 
-----------------------------------------------------------
INSERT INTO RoutePoint (RouteID, PlaceID, OrderInRoute, DistanceKm, DurationMin) VALUES
(1, 1, 1, 0.00, 0),    -- Route 1: Điểm 1 (Mỹ Khê, Start)
(1, 2, 2, 30.50, 45),  -- Route 1: Điểm 2 (Hội An), cách 30.5km, 45 phút
(2, 3, 1, 0.00, 0),    -- Route 2: Điểm 1 (Quán Bà Dưỡng, Start)
(3, 4, 1, 0.00, 0),    -- Route 3: Điểm 1 (Khách sạn Mường Thanh, Start)
(4, 5, 1, 0.00, 0),    -- Route 4: Điểm 1 (Bà Nà Hills, Start)
(6, 8, 1, 0.00, 0),    -- Route 6: Điểm 1 (Lăng Bác, Start)
(6, 9, 2, 2.50, 15),   -- Route 6: Điểm 2 (Hồ Gươm), cách 2.5km, 15 phút
(7, 7, 1, 0.00, 0),    -- Route 7: Điểm 1 (Dinh Độc Lập, Start)
(7, 10, 2, 1.20, 5),   -- Route 7: Điểm 2 (Nhà hàng Chay), cách 1.2km, 5 phút
(8, 1, 1, 0.00, 0),    -- Route 8: Điểm 1 (Mỹ Khê, Start)
(8, 15, 2, 3.80, 10),  -- Route 8: Điểm 2 (Cầu Rồng), cách 3.8km, 10 phút
(9, 2, 1, 0.00, 0),    -- Route 9: Điểm 1 (Hội An, Start)
(10, 6, 1, 0.00, 0),   -- Route 10: Điểm 1 (Phố đi bộ, Start)
(10, 12, 2, 1.50, 8),  -- Route 10: Điểm 2 (Chợ Bến Thành), cách 1.5km, 8 phút
(13, 13, 1, 0.00, 0);  -- Route 13: Điểm 1 (Bảo tàng Lịch sử, Start)
GO




    

 -- trigger tự động tăng totalspent khi đặt tour thành công
CREATE TRIGGER TG_Order_AddSpent
ON [Order]
AFTER INSERT
AS
BEGIN
    UPDATE Users
    SET TotalSpent = TotalSpent + i.FinalAmount
    FROM Users u
    JOIN inserted i ON u.UserID = i.UserID;
END
GO

-- trigger ngăn nhân viên sửa dữ liệu khi không có xác nhận của khách
ALTER TABLE Users 
ADD AllowStaffEdit BIT NOT NULL DEFAULT 0;
GO


CREATE TRIGGER trg_StaffUpdateUser
ON Users
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Nếu khách KHÔNG cho phép sửa (AllowStaffEdit = 0) → chặn thao tác
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Users u ON i.UserID = u.UserID
        WHERE u.AllowStaffEdit = 0
    )
    BEGIN
        RAISERROR ('Khách hàng chưa cho phép nhân viên chỉnh sửa thông tin.', 16, 1);
        RETURN;
    END;

    -- Nếu khách cho phép → cho phép update bình thường
    UPDATE U
    SET 
        UserName = i.UserName,
        BirthDate = i.BirthDate,
        Email = i.Email,
        Phone = i.Phone,
        AvatarUrl = i.AvatarUrl,
        Status = i.Status,
        TotalSpent = i.TotalSpent,
        AllowStaffEdit = i.AllowStaffEdit  -- nhân viên có thể tắt quyền sau khi chỉnh sửa
    FROM Users U
    INNER JOIN inserted i ON U.UserID = i.UserID;
END;
GO

GO
-- procedure đặt tour + giao dịch
CREATE PROCEDURE SP_BookTour
    @UserID INT,
    @TourID INT,
    @Quantity INT,
    @VoucherID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Price DECIMAL(12,2);
        DECLARE @Total DECIMAL(12,2);

        SELECT @Price = Price FROM Tour WHERE TourID = @TourID;

        IF @Price IS NULL
        BEGIN
            RAISERROR('Tour not found.',16,1);
        END

        SELECT @Total = @Price * @Quantity;

        INSERT INTO [Order](UserID,TotalAmount,VoucherID,Status)
        VALUES (@UserID,@Total,@VoucherID,'Pending');

        DECLARE @OrderID INT = SCOPE_IDENTITY();

        INSERT INTO OrderDetail(OrderID,TourID,Quantity,UnitPrice)
        VALUES (@OrderID,@TourID,@Quantity,@Price);

        UPDATE Tour
        SET AvailableSlots = AvailableSlots - @Quantity
        WHERE TourID = @TourID AND AvailableSlots >= @Quantity;

        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Not enough slots.',16,1);
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


-- cusor + procedure gửi voucher cho tất cả uservip

CREATE PROCEDURE SP_SendVoucherToVIP
AS
BEGIN
    DECLARE @UserID INT;

    DECLARE vip_cursor CURSOR FOR
        SELECT UserID FROM Users WHERE MemberLevel='VIP';

    OPEN vip_cursor;
    FETCH NEXT FROM vip_cursor INTO @UserID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO Voucher(Code,Description,DiscountPercent,ApplicableLevel,ExpiryDate)
        VALUES (
            CONCAT('VIP',@UserID,RIGHT(ABS(CHECKSUM(NEWID())),5)),
            'Voucher tặng riêng khách VIP',
            20,
            'VIP',
            DATEADD(month,1,GETDATE())
        );

        FETCH NEXT FROM vip_cursor INTO @UserID;
    END

    CLOSE vip_cursor;
    DEALLOCATE vip_cursor;
END
GO




-- Quản lí người dùng và phân quyền
CREATE LOGIN StaffLogin WITH PASSWORD='Vietwander xin chao';
CREATE USER StaffUser FOR LOGIN StaffLogin;
GO


-- chỉ cho nhân viên xem dữ liệu người dùng và tour người dùng đã đặt, cho phép hủy tour 
-- PHÂN QUYỀN
CREATE LOGIN AdminLogin WITH PASSWORD = 'Vietwander xin chao';
CREATE USER AdminUser FOR LOGIN AdminLogin;
GO

CREATE ROLE StaffRole;
GO

-- Quyền xem dữ liệu người dùng
GRANT SELECT ON Users TO StaffRole;

-- Quyền xem Tour & Booking
GRANT SELECT ON Tour TO StaffRole;
GRANT SELECT ON [Order] TO StaffRole;
GRANT SELECT ON OrderDetail TO StaffRole;
-- Quyền hủy Booking (DELETE)
GRANT DELETE ON [Order] TO StaffRole;
GRANT DELETE ON OrderDetail TO StaffRole;

GO

ALTER ROLE StaffRole ADD MEMBER AdminUser;



CREATE ROLE ManagerRole;
GO

GRANT CONTROL ON DATABASE::Tour_Project TO ManagerRole;
GO

ALTER ROLE ManagerRole ADD MEMBER AdminUser;


-- trigger ghi lịch sử chỉnh sửa
CREATE TABLE AuditLog
(
    LogID INT PRIMARY KEY IDENTITY(1,1),
    TableName NVARCHAR(100),
    Action NVARCHAR(10),
    AdminName NVARCHAR(255),
    TimeStamp DATETIME DEFAULT GETDATE(),
    Detail NVARCHAR(MAX)
);
GO

-- Đảm bảo bảng AuditLog đã tồn tại
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AuditLog' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.AuditLog
    (
        LogID INT PRIMARY KEY IDENTITY(1,1),
        TableName NVARCHAR(100),
        Action NVARCHAR(10),
        UserName NVARCHAR(255),
        TimeStamp DATETIME DEFAULT GETDATE(),
        Detail NVARCHAR(MAX)
    );
END
GO

-- Tạo / thay thế trigger an toàn, không giả định cột cụ thể
CREATE OR ALTER TRIGGER TG_Log_Update_Place
ON dbo.Place
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy admin từ session context, CONVERT để tránh lỗi sql_variant -> nvarchar
    DECLARE @AdminEmail NVARCHAR(255);
    SET @AdminEmail = CONVERT(NVARCHAR(255), SESSION_CONTEXT(N'AdminEmail'));

    IF (@AdminEmail IS NULL OR LTRIM(RTRIM(@AdminEmail)) = '')
        SET @AdminEmail = ORIGINAL_LOGIN();  -- fallback

    -- Chèn một hàng log cho mỗi bản ghi thay đổi
    INSERT INTO dbo.AuditLog (TableName, Action, AdminName, Detail)
    SELECT
        'Place' AS TableName,
        'UPDATE' AS Action,
        @AdminEmail AS UserName,
        -- Detail gồm row cũ và row mới dưới dạng XML (an toàn cho mọi schema)
        CONCAT(
            'Old=', 
            ISNULL(
                CONVERT(NVARCHAR(MAX),
                    (SELECT d2.* 
                     FROM deleted d2 
                     WHERE d2.PlaceID = d.PlaceID
                     FOR XML RAW('row'), TYPE).value('.', 'NVARCHAR(MAX)')
                ), 
            'NULL'),
            '; New=',
            ISNULL(
                CONVERT(NVARCHAR(MAX),
                    (SELECT i2.* 
                     FROM inserted i2 
                     WHERE i2.PlaceID = i.PlaceID
                     FOR XML RAW('row'), TYPE).value('.', 'NVARCHAR(MAX)')
                ),
            'NULL')
        ) AS Detail
    FROM inserted i
    LEFT JOIN deleted d ON i.PlaceID = d.PlaceID;
END;
GO
