using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace KuaforApi.Migrations
{
    public partial class AddAuthAvailabilityCampaignCode : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Username",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AuthProvider",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProviderId",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Users",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "NOW()");

            migrationBuilder.AddColumn<string>(
                name: "Code",
                table: "Campaigns",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "StylistAvailabilities",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    StylistId = table.Column<int>(type: "integer", nullable: false),
                    DayOfWeek = table.Column<int>(type: "integer", nullable: false),
                    IsOpen = table.Column<bool>(type: "boolean", nullable: false),
                    OpenTime = table.Column<TimeSpan>(type: "interval", nullable: false),
                    CloseTime = table.Column<TimeSpan>(type: "interval", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StylistAvailabilities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StylistAvailabilities_Users_StylistId",
                        column: x => x.StylistId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Users_Username",
                table: "Users",
                column: "Username",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_StylistAvailabilities_StylistId_DayOfWeek",
                table: "StylistAvailabilities",
                columns: new[] { "StylistId", "DayOfWeek" },
                unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "StylistAvailabilities");
            migrationBuilder.DropIndex(name: "IX_Users_Username", table: "Users");
            migrationBuilder.DropColumn(name: "Username", table: "Users");
            migrationBuilder.DropColumn(name: "AuthProvider", table: "Users");
            migrationBuilder.DropColumn(name: "ProviderId", table: "Users");
            migrationBuilder.DropColumn(name: "CreatedAt", table: "Users");
            migrationBuilder.DropColumn(name: "Code", table: "Campaigns");
        }
    }
}
