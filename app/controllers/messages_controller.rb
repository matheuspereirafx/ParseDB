
    end
  end

  private


  end

  def message_params
    params.require(:message).permit(:content)
  end
end
