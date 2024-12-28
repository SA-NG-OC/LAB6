CREATE DATABASE DEON3
USE DEON3

CREATE TABLE DOCGIA (
    MaDG CHAR(5) PRIMARY KEY, 
    HoTen VARCHAR(30),
    NgaySinh SMALLDATETIME,
    DiaChi VARCHAR(30),
    SoDT VARCHAR(15)
);

CREATE TABLE SACH (
    MaSach CHAR(5) PRIMARY KEY, 
    TenSach VARCHAR(25),
    TheLoai VARCHAR(25),
    NhaXuatBan VARCHAR(30)
);

CREATE TABLE PHIEUTHUE (
    MaPM CHAR(5) PRIMARY KEY, 
    MaDG CHAR(5),
    NgayThue SMALLDATETIME,
    NgayTra SMALLDATETIME,
    SoSachMuon INT,
    FOREIGN KEY (MaDG) REFERENCES DOCGIA(MaDG)
);

CREATE TABLE CHITIET_PM (
    MaPM CHAR(5), 
    MaSach CHAR(5),
    PRIMARY KEY (MaPM, MaSach),
    FOREIGN KEY (MaPM) REFERENCES PHIEUTHUE(MaPM),
    FOREIGN KEY (MaSach) REFERENCES SACH(MaSach)
);

--2. Hiện thực các ràng buộc toàn vẹn sau:  
--2.1. Mỗi lần thuê  sách, độc giả không được thuê quá 10 ngày. (1.5 đ)  
GO
CREATE TRIGGER trg_KiemTraNgayThue
ON PHIEUTHUE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE DATEDIFF(DAY, i.NgayThue, i.NgayTra) > 10
    )
    BEGIN
        RAISERROR ('Mỗi lần thuê sách không được quá 10 ngày.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

--2.2. Số sách thuê trong bảng phiếu thuê bằng tổng số lần thuê sách có trong bảng chi tiết phiếu thuê. (1.5 đ) 
GO
CREATE TRIGGER trg_KiemTraSoSachMuon
ON CHITIET_PM
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM PHIEUTHUE pt
        JOIN (
            SELECT MaPM, COUNT(*) AS SoSachChiTiet
            FROM CHITIET_PM
            GROUP BY MaPM
        ) ct ON pt.MaPM = ct.MaPM
        WHERE pt.SoSachMuon <> ct.SoSachChiTiet
    )
    BEGIN
        RAISERROR ('Số sách thuê trong phiếu thuê không khớp với chi tiết phiếu thuê.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
--3. Viết các câu lệnh SQL thực hiện các câu truy vấn sau:  
--3.1. Tìm các độc giả (MaDG,HoTen) đã thuê sách thuộc thể loại “Tin học” trong năm 2007. (1.5 đ)  
SELECT DISTINCT dg.MaDG, dg.HoTen
FROM DOCGIA dg
JOIN PHIEUTHUE pt ON dg.MaDG = pt.MaDG
JOIN CHITIET_PM ct ON pt.MaPM = ct.MaPM
JOIN SACH s ON ct.MaSach = s.MaSach
WHERE s.TheLoai = N'Tin học'
AND YEAR(pt.NgayThue) = 2007;
--3.2. Tìm các độc giả (MaDG,HoTen) đã thuê nhiều thể loại sách nhất. (1.5 đ)  
SELECT TOP 1 WITH TIES dg.MaDG, dg.HoTen, COUNT(DISTINCT s.TheLoai) AS SoTheLoai
FROM DOCGIA dg
JOIN PHIEUTHUE pt ON dg.MaDG = pt.MaDG
JOIN CHITIET_PM ct ON pt.MaPM = ct.MaPM
JOIN SACH s ON ct.MaSach = s.MaSach
GROUP BY dg.MaDG, dg.HoTen
ORDER BY SoTheLoai DESC;
--3.3. Trong mỗi thể loại sách, cho biết tên sách được thuê nhiều nhất. (1 đ) 
WITH SoLuongThue AS (
    SELECT s.TheLoai, s.TenSach, COUNT(*) AS SoLanThue
    FROM SACH s
    JOIN CHITIET_PM ct ON s.MaSach = ct.MaSach
    GROUP BY s.TheLoai, s.TenSach
),
MaxThue AS (
    SELECT TheLoai, MAX(SoLanThue) AS MaxLanThue
    FROM SoLuongThue
    GROUP BY TheLoai
)
SELECT slt.TheLoai, slt.TenSach, slt.SoLanThue
FROM SoLuongThue slt
JOIN MaxThue mt ON slt.TheLoai = mt.TheLoai AND slt.SoLanThue = mt.MaxLanThue;