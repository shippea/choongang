<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
	<h2>연산결과 오류 시 Java Script 이용 처리</h2>

	<!-- java code는 <% %>를 통해 이어서 쓸 수 있음-->

<%
	try {
		int num1 = Integer.parseInt(request.getParameter("num1"));
		int num2 = Integer.parseInt(request.getParameter("num2"));
		
		out.println(num1 + " + " + num2 + " = " + (num1+num2) + "<p>");
		out.println(num1 + " - " + num2 + " = " + (num1-num2) + "<p>");
		out.println(num1 + " * " + num2 + " = " + (num1*num2) + "<p>");
		out.println(num1 + " / " + num2 + " = " + (num1/num2) + "<p>");
	} catch (NumberFormatException nfe) { 

%>
	<script type="text/javascript">
		alert("그게 숫자냐");
		// 전페이지로 이동
		history.go(-1);
	</script>

<% 
	} catch(ArithmeticException ae) { 
%>
	<script type="text/javascript">
		alert("0으로 못나눠");
		// 전페이지로 이동
		history.back();
	</script>
	
<% 
	} catch(Exception e) {
	out.println(e.getMessage());
%>	
	<script type="text/javascript">
		alert("하여튼 에러야");
		location.href="num2.jsp";
	</script>
	
<% 
	}
%>

</body>
</html>

