"""
URL configuration for practice0419_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.urls import path
from myapp.views import (UserRegistrationView,UserLoginView,ProductListView,OrderManagementView,
                         UserProfileView,SendVerificationCodeView,PasswordResetView)
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView

urlpatterns = [
    path('api/orders/', OrderManagementView.as_view(), name='orders'),
    path('api/user/info', UserProfileView.as_view(), name='user_info'),
    path('api/register/', UserRegistrationView.as_view(), name='register'),
    path('api/login/', UserLoginView.as_view(), name='login'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    path('api/products/', ProductListView.as_view(), name='products'),
    path('api/send_verification_code/',SendVerificationCodeView.as_view(),name='send_verification_code'),
    path('api/reset_password/',PasswordResetView.as_view(),name='reset_password'),
    path('api/orders/<int:order_id>/cancel/', OrderManagementView.as_view(), name='orders_cancel'),
]
